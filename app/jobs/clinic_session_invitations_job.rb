# frozen_string_literal: true

class ClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session
        .send_invitations
        .includes(
          :dates,
          :programmes,
          patient_sessions: %i[
            consents
            patient
            session_notifications
            vaccination_records
          ]
        )
        .joins(:location)
        .merge(Location.clinic)
        .strict_loading

    sessions.each do |session|
      session_date = session.today_or_future_dates.first

      session.patient_sessions.each do |patient_session|
        next unless should_send_notification?(patient_session:, session_date:)

        type =
          if patient_session.session_notifications.any?
            :clinic_subsequent_invitation
          else
            :clinic_initial_invitation
          end

        SessionNotification.create_and_send!(
          patient_session:,
          session_date:,
          type:
        )
      end
    end
  end

  def should_send_notification?(patient_session:, session_date:)
    return false unless patient_session.send_notifications?

    return false if patient_session.vaccination_administered?

    already_sent_notification =
      patient_session.session_notifications.any? do
        _1.session_date == session_date
      end

    return false if already_sent_notification

    return false if patient_session.consent_refused?

    true
  end
end
