# frozen_string_literal: true

class RemoveDPSExportTables < ActiveRecord::Migration[8.0]
  def up
    # Drop the join table first (due to foreign key constraints)
    if table_exists?(:dps_exports_vaccination_records)
      drop_table :dps_exports_vaccination_records
    end

    # Drop the main dps_exports table
    drop_table :dps_exports if table_exists?(:dps_exports)
  end

  def down
    # Recreate the dps_exports table
    create_table :dps_exports do |t|
      t.string :message_id
      t.string :status, null: false, default: "pending"
      t.string :filename, null: false
      t.timestamp :sent_at
      t.references :programme, null: false, foreign_key: true
      t.timestamps
    end

    # Recreate the join table
    create_join_table :dps_exports, :vaccination_records do |t|
      t.index %i[dps_export_id vaccination_record_id],
              unique: true,
              name: "index_dps_exports_vaccination_records_uniqueness"
      t.index %i[vaccination_record_id dps_export_id],
              name: "index_vaccination_records_dps_exports"
    end
  end
end
