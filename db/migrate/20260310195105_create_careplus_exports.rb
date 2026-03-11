# frozen_string_literal: true

class CreateCareplusExports < ActiveRecord::Migration[8.1]
  def change
    create_table :careplus_exports do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :academic_year, null: false
      t.enum :programme_types,
             array: true,
             enum_type: :programme_type,
             null: false
      t.date :date_from, null: false
      t.date :date_to, null: false
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.text :csv_filename
      t.text :csv_data
      t.datetime :csv_removed_at
      t.timestamps

      t.index :programme_types, using: :gin
      t.index %i[team_id academic_year]
      t.index %i[status scheduled_at]
    end
  end
end
