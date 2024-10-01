# frozen_string_literal: true

class ConsentRemindersJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    Session.send_consent_reminders_today.each do |session|
      session
        .patients
        .needing_consent_reminder(session.programmes)
        .each do |patient|
          session.programmes.each do |programme|
            ConsentNotification.create_and_send!(
              patient:,
              programme:,
              session:,
              reminder: true
            )
          end
        end
    end
  end
end
