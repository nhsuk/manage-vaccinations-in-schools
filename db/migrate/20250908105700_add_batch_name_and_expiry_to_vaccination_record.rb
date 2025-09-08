# frozen_string_literal: true

class AddBatchNameAndExpiryToVaccinationRecord < ActiveRecord::Migration[8.0]
  def up
    change_table :vaccination_records, bulk: true do |t|
      t.string :batch_name
      t.date :batch_expiry
    end

    # Enforce mutual exclusivity between batch_id and the manual batch fields
    # - If batch_id is present, batch_name and batch_expiry must both be NULL
    # - If either batch_name or batch_expiry is present, batch_id must be NULL
    add_check_constraint :vaccination_records,
                         "batch_id IS NULL OR (batch_name IS NULL AND batch_expiry IS NULL)",
                         name: "batch_name_expiry_exclusive_check"
  end

  def down
    remove_check_constraint :vaccination_records,
                            name: "batch_name_expiry_exclusive_check"

    change_table :vaccination_records, bulk: true do |t|
      t.remove :batch_expiry, type: :date
      t.remove :batch_name, type: :string
    end
  end
end
