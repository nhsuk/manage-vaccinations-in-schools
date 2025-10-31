# frozen_string_literal: true

class EnqueueVaccinationsSearchInNHSJob < ApplicationJob
  queue_as :immunisations_api

  def perform(sessions = nil)
    scope =
      if sessions
        Session.where(id: sessions.map(&:id))
      else
        Session.scheduled_for_search_in_nhs_immunisations_api
      end

    scope.find_each do |session|
      ids = session.patients.pluck(:id)
      next if ids.empty?

      SearchVaccinationRecordsInNHSJob.perform_bulk(ids.zip)
    end
  end
end
