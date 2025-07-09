# frozen_string_literal: true

class SendSchoolConsentRequestsJob < SendSchoolConsentNotificationJob
  def should_send_notification?(patient:, session:, programmes:)
    return false unless patient.send_notifications?

    academic_year = session.academic_year

    suitable_programmes =
      programmes.select do |programme|
        patient.consent_status(programme:, academic_year:).no_response? &&
          patient.vaccination_status(programme:, academic_year:).none_yet?
      end

    return false if suitable_programmes.empty?

    suitable_programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end

  def notification_type(patient:, programmes:) # rubocop:disable Lint/UnusedMethodArgument
    :request
  end
end
