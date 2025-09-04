# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session)
    raise InvalidLocation unless session.clinic?

    session_date = session.next_date(include_today: true)
    raise NoSessionDates if session_date.nil?

    patients(session, session_date:).each do |patient|
      send_notification(patient:, session:, session_date:)
    end
  end

  def patients(session, session_date:)
    programmes = session.programmes

    # We only send initial invitations to patients who haven't already
    # received an invitation.

    session
      .patients
      .includes(
        :consent_statuses,
        :consents,
        :parents,
        :session_notifications,
        :vaccination_records,
        :vaccination_statuses
      )
      .reject { it.session_notifications.any? { it.session_id == session.id } }
      .select do |patient|
        should_send_notification?(
          patient:,
          session:,
          programmes:,
          session_date:
        )
      end
  end
end
