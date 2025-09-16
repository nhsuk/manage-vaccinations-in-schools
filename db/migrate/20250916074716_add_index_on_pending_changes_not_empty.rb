# frozen_string_literal: true

class AddIndexOnPendingChangesNotEmpty < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :patients,
              :id,
              where: "pending_changes <> '{}'",
              algorithm: :concurrently,
              name: "index_patients_on_pending_changes_not_empty"
    add_index :vaccination_records,
              :id,
              where: "pending_changes <> '{}'",
              algorithm: :concurrently,
              name: "index_vaccination_records_on_pending_changes_not_empty"
  end
end
