# frozen_string_literal: true

class AddConsentStatusToPatientProgrammeStatuses < ActiveRecord::Migration[8.1]
  def change
    change_table :patient_programme_statuses, bulk: true do |t|
      t.integer :consent_status, default: 0
      t.integer :consent_vaccine_methods, array: true, default: []
    end
  end
end
