# frozen_string_literal: true

namespace :data_migration do
  desc "Renames all the pending changes `batch_id`s to `batch_number`s"
  task rename_pending_changes_batch_id: :environment do
    VaccinationRecord
      .where("pending_changes ? 'batch_id'")
      .find_each do |record|
        record.pending_changes["batch_number"] = record.pending_changes.delete(
          "batch_id"
        )
        record.save!(touch: false)
      end
  end
end
