# frozen_string_literal: true

class RenamePatientSessionRegistrationStatus < ActiveRecord::Migration[8.0]
  def change
    rename_table :patient_session_registration_statuses,
                 :patient_registration_statuses
  end
end
