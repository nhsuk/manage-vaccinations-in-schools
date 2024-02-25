# This job triggers a job to send a batch of consent reminders for each sessions
# that needs them sent today.

class ConsentRemindersJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Session.active.each do |session|
      if session.send_reminders_at&.today?
        ConsentRemindersSessionBatchJob.perform_later(session)
      end
    end
  end
end
