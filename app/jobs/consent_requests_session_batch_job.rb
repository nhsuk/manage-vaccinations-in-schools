# frozen_string_literal: true

# This job sends consent requests for a session.
#
# Each patient that hasn't been sent a consent request yet will be sent one.
# Typically this should happen on the day that the session has set as the date
# for sending consent requests.
#
# It is safe to re-run this job as it marks each patient as having been sent a
# consent request, however only one of these jobs should be run at a time as
# once started this job is not concurrency-safe.

class ConsentRequestsSessionBatchJob < ApplicationJob
  queue_as :default

  def perform(session)
    session.patients.consent_request_not_sent.each do |patient|
      patient.parents.each do |parent|
        ConsentMailer.with(parent:, patient:, session:).request.deliver_now
        TextDeliveryJob.perform_later(
          :consent_request,
          parent:,
          patient:,
          session:
        )
      end

      patient.update!(consent_request_sent_at: Time.zone.now)
    end
  end
end
