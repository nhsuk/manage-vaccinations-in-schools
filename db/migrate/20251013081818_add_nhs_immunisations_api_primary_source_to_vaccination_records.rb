# frozen_string_literal: true

class AddNHSImmunisationsAPIPrimarySourceToVaccinationRecords < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_primary_source,
               :boolean

    # nhs_immunisations_api_primary_source can only be populated if the record's source is 'nhs_immunisations_api'
    add_check_constraint :vaccination_records,
                         "nhs_immunisations_api_primary_source IS NULL OR source = 2",
                         name:
                           "nhs_immunisations_api_primary_source_requires_nhs_immunisations_api_source"
  end
end
