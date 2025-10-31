# frozen_string_literal: true

class RenamePendingChangesToDataAndAddChangesetTypeAndMakeRowNullable < ActiveRecord::Migration[
  8.1
]
  def up
    change_table :patient_changesets, bulk: true do |t|
      t.rename :pending_changes, :data
      t.integer :record_type, null: false, default: 1
      t.change_null :row_number, true
    end
  end

  def down
    change_table :patient_changesets, bulk: true do |t|
      t.change_null :row_number, false
      t.remove :record_type
      t.rename :data, :pending_changes
    end
  end
end
