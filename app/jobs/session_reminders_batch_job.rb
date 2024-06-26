# frozen_string_literal: true

class SessionRemindersBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patients.not_reminded_about_session.each do |patient|
      SessionMailer.session_reminder(session:, patient:).deliver_now
      patient.update!(session_reminder_sent_at: Time.zone.now)
    end
  end
end
