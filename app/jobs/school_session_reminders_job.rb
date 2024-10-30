# frozen_string_literal: true

class SchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes(
          :consents,
          :gillick_assessments,
          :triages,
          :vaccination_records,
          patient: :parents
        )
        .joins(:location, :session)
        .merge(Location.school)
        .merge(Session.has_date(date))
        .notification_not_sent(date)
        .strict_loading

    patient_sessions.each do |patient_session|
      next unless should_send_notification?(patient_session:)

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type: :school_reminder
      )
    end
  end

  def should_send_notification?(patient_session:)
    return false unless patient_session.send_notifications?

    return false if patient_session.vaccination_administered?

    patient_session.consent_given_triage_not_needed? ||
      patient_session.triaged_ready_to_vaccinate?
  end
end
