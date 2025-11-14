# frozen_string_literal: true

class RemovePatientChangesetPendingChangesColumn < ActiveRecord::Migration[8.1]
  def change
    change_table :patient_changesets, bulk: true do |t|
      t.remove :pending_changes, type: :jsonb
    end
  end
end
