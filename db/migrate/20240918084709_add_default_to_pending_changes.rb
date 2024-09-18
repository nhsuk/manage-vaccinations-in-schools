# frozen_string_literal: true

class AddDefaultToPendingChanges < ActiveRecord::Migration[7.2]
  def up
    VaccinationRecord.where(pending_changes: nil).update_all(
      pending_changes: {
      }
    )

    change_table :vaccination_records, bulk: true do |t|
      t.change_default :pending_changes, {}
      t.change_null :pending_changes, false
    end
  end

  def down
    change_table :vaccination_records, bulk: true do |t|
      t.change_default :pending_changes, nil
      t.change_null :pending_changes, true
    end
  end
end
