# frozen_string_literal: true

class CreatePatientSpecificDirections < ActiveRecord::Migration[8.0]
  def change
    create_table :patient_specific_directions do |t|
      t.references :created_by_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }
      t.references :patient, null: false, foreign_key: true
      t.references :programme, null: false, foreign_key: true
      t.references :vaccine, null: false, foreign_key: true

      t.integer :vaccine_method, null: false
      t.integer :delivery_site, null: false
      t.boolean :full_dose, null: false

      t.timestamps
    end
  end
end
