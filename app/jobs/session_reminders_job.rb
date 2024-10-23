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

      # We create a record in the database first to avoid sending duplicate emails/texts.
      # If a problem occurs while the emails/texts are sent, they will be in the job
      # queue and restarted at a later date.

      SessionNotification.create!(
        patient: patient_session.patient,
        session: patient_session.session,
        session_date: date
      )

      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer.with(consent:, patient_session:).reminder.deliver_later

        TextDeliveryJob.perform_later(
          :session_reminder,
          consent:,
          patient_session:
        )
      end
    end
  end

  def should_send_notification?(patient_session)
    patient_session.patient.send_notifications? &&
      !patient_session.vaccination_administered?
  end
end
