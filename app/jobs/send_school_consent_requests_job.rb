# frozen_string_literal: true

class SendSchoolConsentRequestsJob < ApplicationJob
  queue_as :notifications

  def perform(session)
    return unless session.school? && session.open_for_consent?

    session
      .patient_sessions
      .includes_programmes
      .includes(patient: %i[consent_notifications consents vaccination_records])
      .find_each do |patient_session|
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

  def should_send_notification?(patient:, programmes:)
    return false unless patient.send_notifications?

    has_consent_or_vaccinated =
      programmes.all? do |programme|
        VaccinatedCriteria.call(
          programme:,
          patient:,
          vaccination_records: patient.vaccination_records
        ) || ConsentedCriteria.call(programme:, patient:)
      end

    return false if has_consent_or_vaccinated

    programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
