# frozen_string_literal: true

# This job sends consent reminders for a session.
#
# Each patient that hasn't been sent a consent reminder yet will be sent one.
# Typically this should happen on the day that the session has set as the date
# for sending consent reminders.
#
# It is safe to re-run this job as it marks each patient as having been sent a
# consent reminder, however only one of these jobs should be run at a time as
# once started this job is not concurrency-safe.

class ConsentRemindersSessionBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patients.needing_consent_reminder.each do |patient|
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
