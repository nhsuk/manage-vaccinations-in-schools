# frozen_string_literal: true

class SessionRemindersBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    patient_sessions =
      session
        .patient_sessions
        .joins(:patient)
        .merge(Patient.not_reminded_about_session)

    patient_sessions.each do |patient_session|
      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer.with(consent:, patient_session:).reminder.deliver_now
      end

      patient_session.patient.update!(session_reminder_sent_at: Time.zone.now)
    end
  end
end
