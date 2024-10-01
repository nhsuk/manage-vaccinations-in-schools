# frozen_string_literal: true

class SessionRemindersJob < ApplicationJob
  queue_as :default

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    date = Date.tomorrow

    patient_sessions(date).each do |patient_session|
      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer.with(consent:, patient_session:).reminder.deliver_later
        TextDeliveryJob.perform_later(
          :session_reminder,
          consent:,
          patient_session:
        )
      end

      patient_session.update!(reminder_sent_at: Time.zone.now)

      SessionNotification.create!(
        patient: patient_session.patient,
        session: patient_session.session,
        session_date: date
      )
    end
  end

  private

  def patient_sessions(date)
    PatientSession
      .includes(:consents, :patient)
      .joins(:session)
      .merge(Session.has_date(date))
      .reminder_not_sent
  end
end
