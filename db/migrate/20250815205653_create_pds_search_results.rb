# frozen_string_literal: true

class CreatePDSSearchResults < ActiveRecord::Migration[7.0]
  def change
    create_table :pds_search_results do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :class_import, null: true, foreign_key: true
      t.references :cohort_import, null: true, foreign_key: true
      t.integer :step, null: false
      t.integer :result, null: false
      t.string :nhs_number
      t.timestamps
    end
  end
end
