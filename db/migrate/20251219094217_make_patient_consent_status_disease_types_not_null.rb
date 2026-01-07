# frozen_string_literal: true

class MakePatientConsentStatusDiseaseTypesNotNull < ActiveRecord::Migration[8.1]
  def change
    change_table :patient_consent_statuses, bulk: true do |t|
      t.change_default :disease_types, from: nil, to: []
      t.change_null :disease_types, false
    end
  end
end
