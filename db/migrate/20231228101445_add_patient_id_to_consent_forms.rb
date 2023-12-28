class AddPatientIdToConsentForms < ActiveRecord::Migration[7.1]
  def change
    add_reference :consent_forms, :patient, foreign_key: true
  end
end
