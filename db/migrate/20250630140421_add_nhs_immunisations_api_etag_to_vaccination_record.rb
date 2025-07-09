# frozen_string_literal: true

class AddNHSImmunisationsAPIEtagToVaccinationRecord < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_etag,
               :string,
               null: true
  end
end
