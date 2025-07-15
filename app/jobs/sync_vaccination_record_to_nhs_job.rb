# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ApplicationJob
  queue_as :immunisation_api

  retry_on Faraday::ServerError, wait: :polynomially_longer

  def perform(vaccination_record)
    if vaccination_record.not_administered?
      # TODO: This will be a delete
      raise "Vaccination record is not administered: #{vaccination_record.id}"
    end

    if vaccination_record.discarded?
      # TODO: This will be a delete
      raise "Vaccination record is discarded: #{vaccination_record.id}"
    end

    last_synced_at = vaccination_record.nhs_immunisations_api_synced_at
    if last_synced_at.present?
      if last_synced_at > vaccination_record.updated_at
        Rails.logger.info(
          "Vaccination record already synced: #{vaccination_record.id}"
        )
      else
        NHS::ImmunisationsAPI.update_immunisation(vaccination_record)
      end
    else
      NHS::ImmunisationsAPI.record_immunisation(vaccination_record)
    end
  end
end
