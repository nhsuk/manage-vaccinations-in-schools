# frozen_string_literal: true

class SessionRemindersBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patient_sessions.reminder_not_sent.each do |patient_session|
      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer.with(consent:, patient_session:).reminder.deliver_now
      end

      patient_session.update!(reminder_sent_at: Time.zone.now)
    end
  end
end
