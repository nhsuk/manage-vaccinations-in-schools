# frozen_string_literal: true

# This job triggers a job to send a batch of consent reminders for each sessions
# that needs them sent today.

class SessionRemindersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    return unless Flipper.enabled?(:scheduled_emails)

    Session.active.tomorrow.each do |session|
      SessionRemindersBatchJob.perform_later(session)
    end
  end
end
