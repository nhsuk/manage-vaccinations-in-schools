# frozen_string_literal: true

namespace :data_migration do
  desc "Back fill `batch_number` and `batch_expiry` columns for all vaccination records, based on the " \
         "batch.name` and `batch.expiry` respectively."
  task back_fill_new_vaccination_record_columns: :environment do
    VaccinationRecord.joins(:batch).update_all(
      "batch_number = batches.name, batch_expiry = batches.expiry"
    )
  end

  desc "Set the separate performed at date and time columns."
  task set_performed_at_date_and_time: :environment do
    VaccinationRecord.where(performed_at_date: nil).update_all(<<~SQL)
      performed_at_date = performed_at::date,
      performed_at_time = (performed_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/London')::time
    SQL
  end

  desc "Sync vaccinations records for patients without NHS numbers"
  task sync_vaccination_records_without_nhs_number: :environment do
    Patient.without_nhs_number.find_each do |patient|
      patient.vaccination_records.sync_all_to_nhs_immunisations_api
    end
  end
end
