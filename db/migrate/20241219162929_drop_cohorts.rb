# frozen_string_literal: true

class DropCohorts < ActiveRecord::Migration[8.0]
  def change
    remove_reference :patients, :cohort
    drop_table :cohorts do |t|
      t.references :organisation, null: false, foreign_key: true
      t.integer :birth_academic_year, null: false
      t.index %i[organisation_id birth_academic_year], unique: true
      t.timestamps
    end
  end
end
