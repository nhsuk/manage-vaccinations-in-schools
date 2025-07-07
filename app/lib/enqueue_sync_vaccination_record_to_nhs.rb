# frozen_string_literal: true

module EnqueueSyncVaccinationRecordToNHS
  def self.call(vaccination_record)
    if Flipper.enabled?(:sync_vaccination_records_to_nhs_on_create) &&
         vaccination_record.programme.type.in?(%w[flu hpv]) &&
         vaccination_record.administered?
      SyncVaccinationRecordToNHSJob.perform_later(vaccination_record)
    end
  end
end
