# frozen_string_literal: true

class AddNHSImmunisationsAPIIdToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_id,
               :string,
               null: true
    add_index :vaccination_records, :nhs_immunisations_api_id, unique: true
  end
end
