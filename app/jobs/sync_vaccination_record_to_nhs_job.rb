# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ApplicationJob
  queue_as :immunisation_api

  retry_on Faraday::ServerError, wait: :polynomially_longer

  def perform(vaccination_record)
    NHS::ImmunisationsAPI.sync_immunisation(vaccination_record)
  end
end
