# frozen_string_literal: true

class AddChosenVaccineToConsentForm < ActiveRecord::Migration[8.0]
  def change
    add_column :consent_forms, :chosen_vaccine, :string
  end
end
