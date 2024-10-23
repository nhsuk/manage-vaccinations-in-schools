# frozen_string_literal: true

class SchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes(:consents, :patient, :vaccination_records)
        .joins(:location, :session)
        .merge(Location.school)
        .merge(Session.has_date(date))
        .notification_not_sent(date)

    patient_sessions.each do |patient_session|
      next unless should_send_notification?(patient_session)

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type: :school_reminder
      )
    end
  end

  def should_send_notification?(patient_session)
    patient_session.patient.send_notifications? &&
      !patient_session.vaccination_administered?
  end
end
