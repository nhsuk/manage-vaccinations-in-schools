# frozen_string_literal: true

class SessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes(:consents, :location, :patient, :vaccination_records)
        .joins(:session)
        .merge(Session.has_date(date))
        .reminder_not_sent(date)

    patient_sessions.each do |patient_session|
      next if patient_session.location.generic_clinic?

      next unless should_send_notification?(patient_session)

      SessionNotification.create_and_send!(patient_session:, session_date: date)
    end
  end

  def should_send_notification?(patient_session)
    patient_session.patient.send_notifications? &&
      !patient_session.vaccination_administered?
  end
end
