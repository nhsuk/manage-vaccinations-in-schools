# frozen_string_literal: true

module EnqueueSyncVaccinationRecordToNHSE
  PROGRAMME_TYPES = %w[flu hpv].freeze

  def self.call(vaccination_record)
    return unless Flipper.enabled?(:sync_vaccination_records_to_nhse_on_create)

    vaccination_records =
      if vaccination_record.respond_to?(:klass)
        vaccination_record
          .recorded_in_service
          .administered
          .where(programmes: { type: PROGRAMME_TYPES })
          .includes(:programme)
      elsif vaccination_record.programme.type.in?(PROGRAMME_TYPES) &&
            vaccination_record.administered? &&
            vaccination_record.recorded_in_service?
        Array(vaccination_record)
      else
        return
      end

    vaccination_records.each do |vaccination_record|
      SyncVaccinationRecordToNHSEJob.perform_later(vaccination_record)
    end
  end
end
