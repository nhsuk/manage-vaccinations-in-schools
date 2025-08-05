# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session, school:, programmes:)
    raise InvalidLocation unless session.clinic?

    session_date = session.next_date(include_today: true)
    raise NoSessionDates if session_date.nil?

    patient_sessions(
      session,
      school:,
      programmes:,
      session_date:
    ).each do |patient_session|
      send_notification(patient_session:, session_date:)
    end
  end

  def patient_sessions(session, school:, programmes:, session_date:)
    # We only send initial invitations to patients who haven't already
    # received an invitation.

    session
      .patient_sessions
      .joins(:patient)
      .includes_programmes
      .includes(
        :session_notifications,
        patient: %i[consents parents vaccination_records]
      )
      .where(patient: { school: })
      .reject { it.session_notifications.any? }
      .select do |patient_session|
        should_send_notification?(patient_session:, programmes:, session_date:)
      end
  end
end
