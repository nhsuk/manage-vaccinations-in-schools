# frozen_string_literal: true

class CreateSchoolMoves < ActiveRecord::Migration[7.2]
  def change
    create_table :school_moves do |t|
      t.references :patient, null: false, foreign_key: true
      t.integer :source, null: false

      # to known school
      t.references :school, foreign_key: { to_table: :locations }
      t.index %i[patient_id school_id], unique: true

      # to unknown school or home-schooled
      t.references :organisation, foreign_key: true
      t.boolean :home_educated
      t.index %i[patient_id home_educated organisation_id], unique: true

      t.timestamps
    end
  end
end
