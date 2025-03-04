# frozen_string_literal: true

class SchoolConsentRequestsJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session
        .send_consent_requests
        .includes(
          :programmes,
          patient_sessions: {
            patient: [
              :consents,
              :parents,
              { consent_notifications: :programmes }
            ]
          }
        )
        .preload(:session_dates)
        .eager_load(:location)
        .merge(Location.school)

    sessions.each do |session|
      next unless session.open_for_consent?

      session.patient_sessions.each do |patient_session|
        ProgrammeGrouper
          .call(patient_session.programmes)
          .each_value do |programmes|
            next unless should_send_notification?(patient_session:, programmes:)

            ConsentNotification.create_and_send!(
              patient: patient_session.patient,
              programmes:,
              session:,
              type: :request
            )
          end
      end
    end
  end

  def should_send_notification?(patient_session:, programmes:)
    return false unless patient_session.send_notifications?

    has_consent_or_vaccinated =
      programmes.all? do |programme|
        patient_session.consent.all(programme:).any? ||
          patient_session.vaccinated?(programme:) ||
          patient_session.unable_to_vaccinate?(programme:)
      end

    return false if has_consent_or_vaccinated

    patient = patient_session.patient

    programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
