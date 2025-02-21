# frozen_string_literal: true

class SchoolConsentRequestsJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session
        .send_consent_requests
        .includes(
          :programmes,
          patients: [
            :consents,
            :parents,
            { consent_notifications: :programmes }
          ]
        )
        .preload(:session_dates)
        .eager_load(:location)
        .merge(Location.school)

    sessions.each do |session|
      next unless session.open_for_consent?

      ProgrammeGrouper
        .call(session.programmes)
        .each_value do |programmes|
          session.patients.each do |patient|
            next unless should_send_notification?(patient:, programmes:)

            ConsentNotification.create_and_send!(
              patient:,
              programmes:,
              session:,
              type: :request
            )
          end
        end
    end
  end

  def should_send_notification?(patient:, programmes:)
    return false unless patient.send_notifications?

    return false if programmes.all? { patient.has_consent?(it) }

    programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
