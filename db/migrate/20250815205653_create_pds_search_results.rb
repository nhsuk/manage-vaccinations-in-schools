# frozen_string_literal: true

class CreatePDSSearchResults < ActiveRecord::Migration[7.0]
  def change
    create_table :pds_search_results do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :import, polymorphic: true
      t.integer :step, null: false
      t.integer :result, null: false
      t.string :nhs_number
      t.timestamps
    end

    add_index :pds_search_results,
              %i[patient_id import_type import_id step],
              unique: true,
              name: "index_pds_search_results_on_patient_import_step"
  end
end
