# frozen_string_literal: true

class ConsentRequestsJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    Session.send_consent_requests_today.each do |session|
      session
        .patients
        .needing_consent_requests(session.programmes)
        .each do |patient|
          already_sent_programme_ids =
            patient.consent_notifications.request.pluck(:programme_id)

          missing_programmes =
            session.programmes.reject do
              already_sent_programme_ids.include?(_1.id)
            end

          missing_programmes.each do |programme|
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
