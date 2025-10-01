# frozen_string_literal: true

class CreateLocationYearGroup < ActiveRecord::Migration[8.0]
  def change
    create_table :location_year_groups do |t|
      t.references :location, foreign_key: { on_delete: :cascade }, null: false
      t.integer :academic_year, null: false
      t.integer :value, null: false
      t.integer :source, null: false
      t.index %i[location_id academic_year value], unique: true
      t.timestamps
    end
  end
end
