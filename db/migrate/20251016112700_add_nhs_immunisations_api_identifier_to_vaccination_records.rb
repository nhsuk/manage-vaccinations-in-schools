# frozen_string_literal: true

class AddNHSImmunisationsAPIIdentifierToVaccinationRecords < ActiveRecord::Migration[
  7.2
]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.column :nhs_immunisations_api_identifier_system, :string
      t.column :nhs_immunisations_api_identifier_value, :string
    end
  end
end
