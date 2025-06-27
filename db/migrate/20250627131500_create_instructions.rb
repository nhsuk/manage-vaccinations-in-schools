# frozen_string_literal: true

class CreateInstructions < ActiveRecord::Migration[8.0]
  def change
    create_table :instructions do |t|
      t.references :created_by_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }
      t.references :patient, null: false, foreign_key: true
      t.references :programme, null: false, foreign_key: true
      t.references :vaccine, null: false, foreign_key: true

      t.string :vaccine_method, null: false
      t.string :delivery_site, null: false
      t.boolean :full_dose, null: false
      t.string :protocol, null: false

      t.timestamps
    end
  end
end
