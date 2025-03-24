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
            patient = patient_session.patient

            next unless should_send_notification?(patient:, programmes:)

            ConsentNotification.create_and_send!(
              patient:,
              programmes:,
              session:,
              type: :request
            )
          end
      end
    end
  end

  def should_send_notification?(patient:, programmes:)
    return false unless patient.send_notifications?

    has_consent_or_vaccinated =
      programmes.all? do |programme|
        patient.consents.any? { it.programme_id == programme.id } ||
          patient.vaccination_records.any? { it.programme_id == programme.id }
      end

    return false if has_consent_or_vaccinated

    programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
