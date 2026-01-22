# frozen_string_literal: true

class SendClinicInitialInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform(session)
    raise InvalidLocation unless session.clinic?

    date = session.next_date(include_today: true)
    raise NoSessionDates if date.nil?

    patients(session).each do |patient|
      ClinicNotification.create_and_send!(
        patient:,
        programmes: session.programmes_for(patient:),
        team: session.team,
        academic_year: session.academic_year,
        type: :initial_invitation
      )
    end
  end

  def patients(session)
    team = session.team
    academic_year = session.academic_year

    session
      .patients
      .includes_statuses
      .includes(
        :clinic_notifications,
        :consents,
        :parents,
        :vaccination_records
      )
      .select do |patient|
        programmes = session.programmes_for(patient:)
        should_send_notification?(patient:, team:, academic_year:, programmes:)
      end
  end

  def should_send_notification?(patient:, team:, academic_year:, programmes:)
    return false unless patient.send_notifications?(team:)

    programme_types = programmes.map(&:type)

    already_invited =
      patient.clinic_notifications.any? do
        it.initial_invitation? && it.team_id == team.id &&
          it.academic_year == academic_year &&
          (programme_types - it.programme_types).empty? # is subset
      end

    # We only send initial invitations to patients who haven't already
    # received an invitation.

    return if already_invited

    programmes.any? do |programme|
      programme_status = patient.programme_status(programme, academic_year:)
      !programme_status.vaccinated? && !programme_status.consent_refused?
    end
  end

  class InvalidLocation < StandardError
  end

  class NoSessionDates < StandardError
  end
end
