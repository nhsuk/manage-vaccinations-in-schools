# frozen_string_literal: true

class SchoolConsentRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    sessions =
      Session
        .send_consent_reminders
        .includes(
          :programmes,
          patients: %i[consents consent_notifications parents]
        )
        .preload(:dates)
        .eager_load(:location)
        .merge(Location.school)
        .strict_loading

    sessions.each do |session|
      session.programmes.each do |programme|
        session.patients.each do |patient|
          next unless should_send_notification?(patient:, programme:, session:)

          sent_initial_reminder =
            patient.consent_notifications.any?(&:initial_reminder?)

          ConsentNotification.create_and_send!(
            patient:,
            programme:,
            session:,
            type:
              sent_initial_reminder ? :subsequent_reminder : :initial_reminder
          )
        end
      end
    end
  end

  def should_send_notification?(patient:, programme:, session:)
    return false unless patient.send_notifications?

    return false if patient.has_consent?(programme)

    return false if patient.consent_notifications.none?(&:request?)

    date_index_to_send_reminder_for =
      patient.consent_notifications.select(&:reminder?).length

    return if date_index_to_send_reminder_for >= session.dates.length

    date_to_send_reminder_for =
      session.dates[date_index_to_send_reminder_for].value
    earliest_date_to_send_reminder =
      date_to_send_reminder_for - session.days_before_consent_reminders.days

    Date.current >= earliest_date_to_send_reminder
  end
end
