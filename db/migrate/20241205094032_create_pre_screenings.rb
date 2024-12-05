# frozen_string_literal: true

class CreatePreScreenings < ActiveRecord::Migration[7.2]
  def change
    create_table :pre_screenings do |t|
      t.references :patient_session, null: false, foreign_key: true
      t.references :performed_by_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }
      t.boolean :knows_vaccination, null: false
      t.boolean :not_already_had, null: false
      t.boolean :feeling_well, null: false
      t.boolean :no_allergies, null: false
      t.text :notes, null: false, default: ""
      t.timestamps
    end
  end
end
