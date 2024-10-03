# frozen_string_literal: true

class CreateClassImports < ActiveRecord::Migration[7.2]
  def change
    create_table :class_imports do |t|
      t.integer :changed_record_count
      t.text :csv_data
      t.text :csv_filename
      t.datetime :csv_removed_at
      t.integer :exact_duplicate_record_count
      t.integer :new_record_count
      t.datetime :processed_at
      t.datetime :recorded_at
      t.json :serialized_errors
      t.integer :status, default: 0, null: false
      t.references :team, foreign_key: true, null: false
      t.references :session, foreign_key: true, null: false
      t.references :uploaded_by_user,
                   foreign_key: {
                     to_table: :users
                   },
                   null: false
      t.timestamps
    end

    column_options = { foreign_key: true }

    create_join_table :class_imports, :parents, column_options: do |t|
      t.index %i[class_import_id parent_id], unique: true
    end

    create_join_table :class_imports,
                      :parent_relationships,
                      column_options: do |t|
      t.index %i[class_import_id parent_relationship_id], unique: true
    end

    create_join_table :class_imports, :patients, column_options: do |t|
      t.index %i[class_import_id patient_id], unique: true
    end
  end
end
