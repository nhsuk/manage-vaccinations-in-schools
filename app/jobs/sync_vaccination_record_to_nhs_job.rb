# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ApplicationJob
  def self.concurrent_jobs_per_second = 2
  def self.concurrency_key = :immunisations_api

  include NHSAPIConcurrencyConcernGoodJob

  queue_as :immunisation_api

  def perform(vaccination_record)
    tx_id = SecureRandom.urlsafe_base64(16)
    SemanticLogger.tagged(tx_id:, job_id: provider_job_id || job_id) do
      Sentry.set_tags(tx_id:, job_id: provider_job_id || job_id)

      NHS::ImmunisationsAPI.sync_immunisation(vaccination_record)
    end
  end
end
