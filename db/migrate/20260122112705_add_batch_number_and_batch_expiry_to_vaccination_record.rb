# frozen_string_literal: true

class AddBatchNumberAndBatchExpiryToVaccinationRecord < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.column :batch_number, :string, null: true
      t.column :batch_expiry, :date, null: true
    end
  end
end
