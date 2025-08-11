# frozen_string_literal: true

class EnqueueClinicSessionInvitationsJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions = Session.send_invitations.joins(:location).merge(Location.clinic)

    sessions.find_each do |session|
      SendClinicInitialInvitationsJob.perform_later(session)
    end
  end
end
