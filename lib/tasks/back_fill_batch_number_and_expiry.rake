# frozen_string_literal: true

namespace :data_migration do
  desc "Back fill `batch_number` and `batch_expiry` columns for all vaccination records, based on the " \
         "batch.name` and `batch.expiry` respectively."
  task back_fill_new_vaccination_record_columns: :environment do
    VaccinationRecord.joins(:batch).update_all(
      "batch_number = batches.name, batch_expiry = batches.expiry"
    )
  end
end
