# frozen_string_literal: true

class ClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    return unless Flipper.enabled?(:scheduled_emails)

    # TODO: when do we want to send these?
    date = 3.weeks.from_now.to_date

    patient_sessions =
      PatientSession
        .includes(
          :consents,
          patient: %i[session_notifications vaccination_records],
          session: :programmes
        )
        .joins(:location, :session)
        .merge(Location.clinic)
        .merge(Session.has_date(date))
        .notification_not_sent(date)
        .strict_loading

    patient_sessions.each do |patient_session|
      next unless should_send_notification?(patient_session:)

      patient = patient_session.patient

      type =
        if patient.session_notifications.any? { _1.session_id == session.id }
          :clinic_subsequent_invitation
        else
          :clinic_initial_invitation
        end

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type:
      )
    end
  end

  def should_send_notification?(patient_session:)
    patient = patient_session.patient
    programmes = patient_session.session.programmes

    return false unless patient.send_notifications?

    return false if programmes.all? { patient.vaccinated?(_1) }

    return false if patient_session.consent_refused?

    true
  end
end
