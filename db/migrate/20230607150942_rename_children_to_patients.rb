# frozen_string_literal: true

class RenameChildrenToPatients < ActiveRecord::Migration[7.0]
  def change
    change_table :children do |t|
      t.rename_index "index_children_on_nhs_number",
                     "index_patients_on_nhs_number"
    end
    rename_table :children, :patients

    rename_table :children_sessions, :patients_sessions
    remove_index :patients_sessions, %i[child_id session_id]
    remove_index :patients_sessions, %i[session_id child_id]
    rename_column :patients_sessions, :child_id, :patient_id
    add_index :patients_sessions, %i[patient_id session_id], unique: true
    add_index :patients_sessions, %i[session_id patient_id], unique: true
  end
end
