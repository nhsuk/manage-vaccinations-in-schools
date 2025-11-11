# frozen_string_literal: true

class EnqueueVaccinationsSearchInNHSJob < ApplicationJob
  queue_as :immunisations_api_search

  def perform(sessions = nil)
    scope =
      if sessions
        Session.where(id: sessions.map(&:id))
      else
        scope = Session.has_any_programmes_of([Programme.flu.sole]).scheduled

        scope.where("sessions.send_invitations_at <= ?", 2.days.from_now).or(
          scope.where("sessions.send_consent_requests_at <= ?", 2.days.from_now)
        )
      end

    scope.find_each do |session|
      ids = session.patients.pluck(:id)
      next if ids.empty?

      SearchVaccinationRecordsInNHSJob.perform_bulk(ids.zip)
    end
  end
end
