# frozen_string_literal: true

class RenameTablePatientsSessionsToPatientSessions < ActiveRecord::Migration[
  7.0
]
  def change
    rename_table :patients_sessions, :patient_sessions
  end
end
