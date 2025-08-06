# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ApplicationJob
  queue_as :immunisation_api

  retry_on Faraday::ServerError, wait: :polynomially_longer

  def perform(vaccination_record)
    tx_id = SecureRandom.urlsafe_base64(16)
    SemanticLogger.tagged(tx_id:, job_id: provider_job_id || job_id) do
      Sentry.set_tags(tx_id:, job_id: provider_job_id || job_id)

      NHS::ImmunisationsAPI.sync_immunisation(vaccination_record)
    end
  end
end
