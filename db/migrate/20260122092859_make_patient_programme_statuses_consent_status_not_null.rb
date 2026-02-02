# frozen_string_literal: true

class MakePatientProgrammeStatusesConsentStatusNotNull < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :patient_programme_statuses, bulk: true do |t|
      t.change_null :consent_status, false
      t.change_null :consent_vaccine_methods, false
    end
  end
end
