# frozen_string_literal: true

module EnqueueSyncVaccinationRecordToNHSE
  def self.call(vaccination_record)
    if Flipper.enabled?(:sync_vaccination_records_to_nhse_on_create) &&
         vaccination_record.programme.type.in?(%w[flu hpv]) &&
         vaccination_record.administered?
      SyncVaccinationRecordToNHSEJob.perform_later(vaccination_record)
    end
  end
end
