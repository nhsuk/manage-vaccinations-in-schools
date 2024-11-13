# frozen_string_literal: true

class AddDiscardedAtToVaccinationRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :vaccination_records, :discarded_at, :datetime
    add_index :vaccination_records, :discarded_at
  end
end
