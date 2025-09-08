# frozen_string_literal: true

class EnqueueVaccinationsSearchInNHSJob < ApplicationJob
  queue_as :immunisations_api

  def perform(sessions = nil)
    sessions ||=
      begin
        flu = Programme.flu.sole
        Session
          .includes(:session_dates)
          .has_programmes([flu])
          .where("sessions.send_invitations_at <= ?", 2.days.from_now)
          .where("session_dates.value >= ?", Time.zone.today)
          .references(:session_dates)
      end

    patient_ids = PatientLocation.where(session: sessions).pluck(:patient_id)

    return if patient_ids.empty?

    SearchVaccinationRecordsInNHSJob.perform_bulk(patient_ids.zip)
  end
end
