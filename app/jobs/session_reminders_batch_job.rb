class SessionRemindersBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patients.each do |patient|
      SessionMailer.session_reminder(session:, patient:).deliver_now
    end
  end
end
