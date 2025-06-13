# frozen_string_literal: true

class AddVaccineMethodsToConsentAndConsentForms < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_form_programmes,
               :vaccine_methods,
               :integer,
               null: false,
               array: true,
               default: []

    add_column :consents,
               :vaccine_methods,
               :integer,
               null: false,
               array: true,
               default: []

    # We don't support getting consent for nasal spray yet.
    reversible do |dir|
      dir.up do
        ConsentFormProgramme.response_given.update_all(
          vaccine_methods: %w[injection]
        )
        Consent.response_given.update_all(vaccine_methods: %w[injection])
      end
    end
  end
end
