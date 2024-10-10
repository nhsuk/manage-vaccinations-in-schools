# frozen_string_literal: true

class ConsentRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    sessions =
      Session
        .send_consent_reminders
        .includes(:programmes, patients: %i[consents consent_notifications])
        .strict_loading

    sessions.each do |session|
      session.programmes.each do |programme|
        session.patients.each do |patient|
          next unless should_send_notification?(patient:, programme:, session:)

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

  def should_send_notification?(patient:, programme:, session:)
    return false if patient.has_consent?(programme)

    if patient.consent_notifications.select(&:reminder).length >=
         session.maximum_number_of_consent_reminders
      return false
    end

    previous_notification = patient.consent_notifications.max_by(&:sent_at)
    return false if previous_notification.nil?

    next_date =
      previous_notification.sent_at.to_date +
        if previous_notification.request?
          session.days_before_first_consent_reminder
        else
          session.days_between_consent_reminders
        end

    Date.current >= next_date
  end
end
