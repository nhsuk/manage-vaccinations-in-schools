# frozen_string_literal: true

class AddNHSESyncedAtToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :nhse_synced_at, :datetime, null: true
  end
end
