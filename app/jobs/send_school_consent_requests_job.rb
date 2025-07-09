# frozen_string_literal: true

class SendSchoolConsentRequestsJob < SendSchoolConsentNotificationJob
  def should_send_notification?(patient:, session:, programmes:) # rubocop:disable Lint/UnusedMethodArgument
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

  def notification_type(patient:, programmes:) # rubocop:disable Lint/UnusedMethodArgument
    :request
  end
end
