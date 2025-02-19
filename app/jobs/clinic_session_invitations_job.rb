# frozen_string_literal: true

class ClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    Session
      .send_invitations
      .joins(:location)
      .merge(Location.clinic)
      .each do |session|
        # We're only inviting patients who don't have a school.
        # Patients who have a school are sent invitations manually by the
        # nurse when they're finished at a school.
        SendClinicInitialInvitationsJob.perform_now(session, school: nil)
      end
  end
end
