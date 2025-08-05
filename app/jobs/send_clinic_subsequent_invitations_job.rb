# frozen_string_literal: true

class SendClinicSubsequentInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session)
    raise InvalidLocation unless session.clinic?

    session_date = session.next_date(include_today: true)
    raise NoSessionDates if session_date.nil?

    patient_sessions(session, session_date:).each do |patient_session|
      send_notification(patient_session:, session_date:)
    end
  end

  def patient_sessions(session, session_date:)
    programmes = session.programmes

    # We only send subsequent invitations (reminders) to patients who
    # have already received an invitation.

    session
      .patient_sessions
      .joins(:patient)
      .includes_programmes
      .includes(
        :session_notifications,
        patient: %i[consents parents vaccination_records]
      )
      .select { it.session_notifications.any? }
      .select do |patient_session|
        should_send_notification?(patient_session:, programmes:, session_date:)
      end
  end
end
