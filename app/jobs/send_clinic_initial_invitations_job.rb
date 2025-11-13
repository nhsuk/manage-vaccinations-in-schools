# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  include SendClinicInvitationsConcern

  queue_as :notifications

  def perform(session)
    raise InvalidLocation unless session.clinic?

    date = session.next_date(include_today: true)
    raise NoSessionDates if date.nil?

    patients(session, date:).each do |patient|
      send_notification(patient:, session:, date:)
    end
  end

  def patients(session, date:)
    programmes = session.programmes

    # We only send initial invitations to patients who haven't already
    # received an invitation.

    session
      .patients
      .includes_statuses
      .includes(
        :consents,
        :parents,
        :session_notifications,
        :vaccination_records
      )
      .reject { it.session_notifications.any? { it.session_id == session.id } }
      .select do |patient|
        should_send_notification?(patient:, session:, programmes:, date:)
      end
  end
end
