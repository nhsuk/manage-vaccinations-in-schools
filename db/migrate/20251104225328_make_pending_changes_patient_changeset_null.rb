# frozen_string_literal: true

class MakePendingChangesPatientChangesetNull < ActiveRecord::Migration[8.1]
  def change
    change_table :patient_changesets, bulk: true do |t|
      t.change_null :pending_changes, true
    end
  end
end
