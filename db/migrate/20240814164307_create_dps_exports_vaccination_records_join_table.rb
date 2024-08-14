# frozen_string_literal: true

class CreateDPSExportsVaccinationRecordsJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :dps_exports, :vaccination_records do |t|
      t.index %i[dps_export_id vaccination_record_id],
              unique: true,
              name: "index_dps_exports_vaccination_records_uniqueness"
      t.index %i[vaccination_record_id dps_export_id],
              name: "index_vaccination_records_dps_exports"
    end

    remove_column :vaccination_records, :exported_to_dps_at, :datetime
  end
end
