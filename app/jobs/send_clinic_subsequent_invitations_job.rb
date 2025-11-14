# frozen_string_literal: true

class SendClinicSubsequentInvitationsJob < ApplicationJob
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

    # We only send subsequent invitations (reminders) to patients who
    # have already received an invitation.

    session
      .patients
      .includes_statuses
      .includes(
        :consents,
        :parents,
        :session_notifications,
        :vaccination_records
      )
      .select { it.session_notifications.any? { it.session_id == session.id } }
      .select do |patient|
        should_send_notification?(patient:, session:, programmes:, date:)
      end
  end
end
