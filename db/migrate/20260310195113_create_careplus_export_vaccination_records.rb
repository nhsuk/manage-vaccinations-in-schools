# frozen_string_literal: true

class CreateCareplusExportVaccinationRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :careplus_export_vaccination_records,
                 primary_key: %i[
                   careplus_export_id
                   vaccination_record_id
                 ] do |t|
      t.references :careplus_export,
                   null: false,
                   foreign_key: {
                     on_delete: :cascade
                   }
      t.references :vaccination_record, null: false, foreign_key: true
      t.integer :change_type, null: false
      t.timestamps
    end
  end
end
