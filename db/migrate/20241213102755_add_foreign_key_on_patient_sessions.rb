# frozen_string_literal: true

class AddForeignKeyOnPatientSessions < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :patient_sessions, :patients
    add_foreign_key :patient_sessions, :sessions
  end
end
