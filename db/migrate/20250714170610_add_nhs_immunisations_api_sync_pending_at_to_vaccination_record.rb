# frozen_string_literal: true

class AddNHSImmunisationsAPISyncPendingAtToVaccinationRecord < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :vaccination_records,
               :nhs_immunisations_api_sync_pending_at,
               :datetime,
               null: true
  end
end
