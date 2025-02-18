# frozen_string_literal: true

class ClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session
        .send_invitations
        .includes(
          :programmes,
          patient_sessions: [
            :session_notifications,
            { patient: %i[consents parents vaccination_records] }
          ]
        )
        .preload(:session_dates)
        .joins(:location)
        .merge(Location.clinic)

    sessions.each do |session|
      session_date = session.today_or_future_dates.first
      programmes = session.programmes

      session.patient_sessions.each do |patient_session|
        unless should_send_notification?(
                 patient_session:,
                 programmes:,
                 session_date:
               )
          next
        end

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

  def should_send_notification?(patient_session:, programmes:, session_date:)
    return false unless patient_session.send_notifications?

    all_vaccinated =
      programmes.all? do |programme|
        patient_session.vaccination_administered?(programme:)
      end

    return false if all_vaccinated

    already_sent_notification =
      patient_session.session_notifications.any? do
        _1.session_date == session_date
      end

    return false if already_sent_notification

    all_consent_refused =
      programmes.all? do |programme|
        patient_session.consent_refused?(programme:)
      end

    return false if all_consent_refused

    true
  end
end
