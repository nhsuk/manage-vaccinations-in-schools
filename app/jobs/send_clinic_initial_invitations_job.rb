# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session, school:, programmes:)
    raise InvalidLocation unless session.clinic?

    session_date = session.next_date
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

    scope =
      session
        .patient_sessions
        .eager_load(:patient)
        .preload(
          :session_notifications,
          patient: %i[consents parents],
          session: :programmes
        )
        .where(patient: { school: })

    outcomes = Outcomes.new(patient_sessions: scope)

    scope
      .reject { it.session_notifications.any? }
      .select do
        should_send_notification?(
          patient_session: it,
          programmes:,
          session_date:,
          outcomes:
        )
      end
  end
end
