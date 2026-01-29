# frozen_string_literal: true

namespace :data_migration do
  desc "Backfills the `Batch.number` column with the data currently in `Batch.name`"
  task backfill_batch_number: :environment do
    Batch.update_all("number = name")
  end
end
