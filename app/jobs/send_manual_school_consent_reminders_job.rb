# frozen_string_literal: true

class SendManualSchoolConsentRemindersJob < ApplicationJob
  include SendSchoolConsentNotificationConcern

  def perform(session, current_user:)
    patient_programmes_eligible_for_notification(
      session:
    ) do |patient, programmes|
      ConsentNotification.create_and_send!(
        patient:,
        session:,
        programmes:,
        type: notification_type(patient:, programmes:),
        current_user:
      )
    end
  end

  def notification_type(patient:, programmes:)
    reminder_notification_type(patient:, programmes:)
  end
end
