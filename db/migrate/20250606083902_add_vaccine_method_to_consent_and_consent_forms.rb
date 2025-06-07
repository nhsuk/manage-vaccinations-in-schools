# frozen_string_literal: true

class AddVaccineMethodToConsentAndConsentForms < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_form_programmes, :vaccine_method, :integer

    add_column :consents, :vaccine_method, :integer

    # We don't support getting consent for nasal spray yet.
    reversible do |dir|
      dir.up do
        ConsentFormProgramme.response_given.update_all(
          vaccine_method: "injection"
        )
        Consent.response_given.update_all(vaccine_method: "injection")
      end
    end

    remove_column :consent_forms, :contact_injection, :boolean
  end
end
