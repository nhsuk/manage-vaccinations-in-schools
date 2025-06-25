# frozen_string_literal: true

class AddNHSImmunisationsAPISyncedAtToVaccinationRecord < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_synced_at,
               :datetime,
               null: true
  end
end
