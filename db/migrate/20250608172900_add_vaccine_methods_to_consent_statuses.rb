# frozen_string_literal: true

class AddVaccineMethodsToConsentStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :patient_consent_statuses,
               :vaccine_methods,
               :integer,
               array: true,
               default: [],
               null: false

    reversible do |dir|
      dir.up do
        # We don't support nasal spray yet.
        Patient::ConsentStatus.given.update_all(vaccine_methods: %w[injection])
      end
    end
  end
end
