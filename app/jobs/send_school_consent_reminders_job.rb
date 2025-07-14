# frozen_string_literal: true

class SendSchoolConsentRemindersJob < SendSchoolConsentNotificationJob
  def notification_type(patient:, programmes:)
    sent_initial_reminder =
      programmes.all? do |programme|
        patient
          .consent_notifications
          .select { it.programmes.include?(programme) }
          .any?(&:initial_reminder?)
      end

    sent_initial_reminder ? :subsequent_reminder : :initial_reminder
  end
end
