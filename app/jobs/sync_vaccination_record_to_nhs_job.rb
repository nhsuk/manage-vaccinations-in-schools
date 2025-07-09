# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ApplicationJob
  queue_as :immunisation_api

  def perform(vaccination_record)
    if vaccination_record.nhs_immunisations_api_synced_at.present?
      Rails.logger.info(
        "Vaccination record already synced: #{vaccination_record.id}"
      )
      return
    end

    NHS::ImmunisationsAPI.record_immunisation(vaccination_record)
  end
end
