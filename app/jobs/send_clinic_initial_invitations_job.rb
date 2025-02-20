# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session, school:)
    raise InvalidLocation unless session.clinic?

    session_date = session.today_or_future_dates.first
    raise NoSessionDates if session_date.nil?

    programmes = session.programmes

    patient_sessions =
      session
        .patient_sessions
        .eager_load(:patient)
        .preload(
          :session_notifications,
          patient: %i[consents parents vaccination_records]
        )
        .where(patient: { school: })

    # We only send initial invitations to patients who haven't already
    # received an invitation.
    patient_sessions
      .reject { it.session_notifications.any? }
      .each do |patient_session|
        send_notification(patient_session:, programmes:, session_date:)
      end
  end
end
