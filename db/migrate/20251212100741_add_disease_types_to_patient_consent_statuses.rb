# frozen_string_literal: true

class AddDiseaseTypesToPatientConsentStatuses < ActiveRecord::Migration[8.1]
  def change
    add_column :patient_consent_statuses,
               :disease_types,
               :integer,
               array: true,
               default: [],
               null: true
  end
end
