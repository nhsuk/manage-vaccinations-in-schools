# frozen_string_literal: true

class UpdatePatientSessionIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :patient_sessions, %i[session_id patient_id], unique: true
    add_index :patient_sessions, :patient_id
    add_index :patient_sessions, :session_id
  end
end
