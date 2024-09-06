# frozen_string_literal: true

class CreateCohortImports < ActiveRecord::Migration[7.2]
  def change
    create_table :cohort_imports do |t|
      t.datetime :csv_removed_at
      t.datetime :processed_at
      t.datetime :recorded_at

      t.text :csv_data
      t.text :csv_filename

      t.integer :new_record_count
      t.integer :exact_duplicate_record_count

      t.references :uploaded_by_user,
                   null: false,
                   foreign_key: {
                     to_table: :users
                   }

      t.timestamps
    end
  end
end
