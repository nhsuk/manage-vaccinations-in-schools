# frozen_string_literal: true

class AddDefaultToPendingChanges < ActiveRecord::Migration[7.2]
  def up
    change_table :vaccination_records, bulk: true do |t|
      t.change_default :pending_changes, {}
      t.change_null :pending_changes, false
    end

    VaccinationRecord.where(pending_changes: nil).update_all(
      pending_changes: {
      }
    )
  end

  def down
    change_column_default :vaccination_records, :pending_changes, nil
  end
end
