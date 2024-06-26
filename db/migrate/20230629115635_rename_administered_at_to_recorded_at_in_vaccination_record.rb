# frozen_string_literal: true

class RenameAdministeredAtToRecordedAtInVaccinationRecord < ActiveRecord::Migration[
  7.0
]
  def change
    rename_column :vaccination_records, :administered_at, :recorded_at
  end
end
