# frozen_string_literal: true

class ConsentRequestsJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    Session.send_consent_requests_today.each do |session|
      session.patients.needing_consent_request.each do |patient|
        session.programmes.each do |programme|
          ConsentNotification.create_and_send!(
            patient:,
            programme:,
            session:,
            reminder: false
          )
        end
      end
    end
  end
end
