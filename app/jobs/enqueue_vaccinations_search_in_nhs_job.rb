# frozen_string_literal: true

class EnqueueVaccinationsSearchInNHSJob < ApplicationJob
  queue_as :immunisations_api

  def perform(sessions = nil)
    scope =
      if sessions
        Session.where(id: sessions.map(&:id))
      else
        flu = Programme.flu.sole
        Session
          .includes(:session_dates)
          .has_programmes([flu])
          .where("sessions.send_consent_requests_at <= ?", 2.days.from_now)
          .where("session_dates.value >= ?", Time.zone.today)
          .references(:session_dates)
      end

    scope.find_each do |session|
      ids = session.patients.pluck(:id)
      next if ids.empty?

      SearchVaccinationRecordsInNHSJob.perform_bulk(ids.zip)
    end
  end
end
