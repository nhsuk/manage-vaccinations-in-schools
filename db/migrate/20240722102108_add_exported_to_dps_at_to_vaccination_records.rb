# frozen_string_literal: true

class AddExportedToDPSAtToVaccinationRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccination_records, :exported_to_dps_at, :datetime
  end
end
