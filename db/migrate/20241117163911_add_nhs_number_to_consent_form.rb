# frozen_string_literal: true

class AddNHSNumberToConsentForm < ActiveRecord::Migration[7.2]
  def change
    add_column :consent_forms, :nhs_number, :string
    add_index :consent_forms, :nhs_number
  end
end
