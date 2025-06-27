# frozen_string_literal: true

class AddSyncedAtToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :synced_at, :datetime, null: true
  end
end
