# frozen_string_literal: true

class SessionRemindersBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patients.not_reminded_about_session.each do |patient|
      patient.parents.each do |parent|
        SessionMailer
          .with(parent:, patient:, session:)
          .session_reminder
          .deliver_now
      end
      patient.update!(session_reminder_sent_at: Time.zone.now)
    end
  end
end
