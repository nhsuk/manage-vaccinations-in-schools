# frozen_string_literal: true

class ConsentRequestsJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    sessions =
      Session
        .send_consent_requests
        .includes(
          :location,
          :programmes,
          patients: %i[consents consent_notifications]
        )
        .strict_loading

    sessions.each do |session|
      next if session.location.generic_clinic?

      session.programmes.each do |programme|
        session.patients.each do |patient|
          next unless should_send_notification?(patient:, programme:)

          ConsentNotification.create_and_send!(
            patient:,
            programme:,
            session:,
            type: :request
          )
        end
      end
    end
  end

  def should_send_notification?(patient:, programme:)
    return false unless patient.send_notifications?

    return false if patient.has_consent?(programme)

    patient.consent_notifications.none? do
      _1.request? && _1.programme_id == programme.id
    end
  end
end
