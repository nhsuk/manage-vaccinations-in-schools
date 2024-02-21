# This job triggers a job to send a batch of consent requests for each sessions
# that needs them sent today.

class ConsentRequestsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Session.active.each do |session|
      if session.send_consent_at&.today?
        ConsentRequestsSessionBatchJob.perform_later(session)
      end
    end
  end
end
