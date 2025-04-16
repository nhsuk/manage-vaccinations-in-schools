# frozen_string_literal: true

class EnqueueClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    Session
      .send_invitations
      .includes(:programmes)
      .joins(:location)
      .merge(Location.clinic)
      .find_each do |session|
        # We're only inviting patients who don't have a school.
        # Patients who have a school are sent invitations manually by the
        # nurse when they're finished at a school.
        SendClinicInitialInvitationsJob.perform_now(
          session,
          school: nil,
          programmes: session.programmes
        )
      end
  end
end
