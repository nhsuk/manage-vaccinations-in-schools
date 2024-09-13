# frozen_string_literal: true

class AddPendingChangesToVaccinationRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :vaccination_records, :pending_changes, :jsonb
  end
end
