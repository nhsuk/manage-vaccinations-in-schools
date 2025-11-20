# frozen_string_literal: true

class SyncVaccinationRecordToNHSJob < ImmunisationsAPIJob
  sidekiq_options queue: :immunisations_api_sync

  def perform(vaccination_record_id)
    vaccination_record = VaccinationRecord.find(vaccination_record_id)

    unless Flipper.enabled?(:imms_api_sync_job, vaccination_record.programme)
      return
    end

    tx_id = SecureRandom.urlsafe_base64(16)

    SemanticLogger.tagged(tx_id:, job_id:) do
      Sentry.set_tags(tx_id:, job_id:)

      NHS::ImmunisationsAPI.sync_immunisation(vaccination_record)
    end
  end
end
