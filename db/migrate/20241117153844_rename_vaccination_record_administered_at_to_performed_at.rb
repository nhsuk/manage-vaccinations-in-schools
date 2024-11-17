# frozen_string_literal: true

class RenameVaccinationRecordAdministeredAtToPerformedAt < ActiveRecord::Migration[
  7.2
]
  def up
    rename_column :vaccination_records, :administered_at, :performed_at
    VaccinationRecord.where(performed_at: nil).update_all(
      "performed_at = created_at"
    )
    change_column_null :vaccination_records, :performed_at, false
  end

  def down
    change_column_null :vaccination_records, :performed_at, true
    VaccinationRecord
      .where.not(outcome: "administered")
      .update_all(performed_at: nil)
    rename_column :vaccination_records, :performed_at, :administered_at
  end
end
