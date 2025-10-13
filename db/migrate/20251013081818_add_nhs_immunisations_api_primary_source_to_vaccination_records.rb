# frozen_string_literal: true

class AddNHSImmunisationsAPIPrimarySourceToVaccinationRecords < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_primary_source,
               :boolean
  end
end
