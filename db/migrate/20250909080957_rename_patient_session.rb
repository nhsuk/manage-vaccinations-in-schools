# frozen_string_literal: true

class RenamePatientSession < ActiveRecord::Migration[8.0]
  def change
    rename_table :patient_sessions, :patient_locations

    rename_table :immunisation_imports_patient_sessions,
                 :immunisation_imports_patient_locations
    rename_column :immunisation_imports_patient_locations,
                  :patient_session_id,
                  :patient_location_id
  end
end
