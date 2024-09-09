# frozen_string_literal: true

class AddCSVImportableJoinTables < ActiveRecord::Migration[7.2]
  def change
    column_options = { foreign_key: true }

    create_join_table :cohort_imports, :patients, column_options: do |t|
      t.index %i[cohort_import_id patient_id], unique: true
    end

    create_join_table :immunisation_imports, :batches, column_options: do |t|
      t.index %i[immunisation_import_id batch_id], unique: true
    end

    create_join_table :immunisation_imports, :locations, column_options: do |t|
      t.index %i[immunisation_import_id location_id], unique: true
    end

    create_join_table :immunisation_imports,
                      :patient_sessions,
                      column_options: do |t|
      t.index %i[immunisation_import_id patient_session_id], unique: true
    end

    create_join_table :immunisation_imports, :patients, column_options: do |t|
      t.index %i[immunisation_import_id patient_id], unique: true
    end

    create_join_table :immunisation_imports, :sessions, column_options: do |t|
      t.index %i[immunisation_import_id session_id], unique: true
    end

    create_join_table :immunisation_imports,
                      :vaccination_records,
                      column_options: do |t|
      t.index %i[immunisation_import_id vaccination_record_id], unique: true
    end

    remove_reference :locations,
                     :imported_from,
                     foreign_key: {
                       to_table: :immunisation_imports
                     }

    remove_reference :patients,
                     :imported_from,
                     foreign_key: {
                       to_table: :immunisation_imports
                     }

    remove_reference :sessions,
                     :imported_from,
                     foreign_key: {
                       to_table: :immunisation_imports
                     }

    remove_reference :vaccination_records,
                     :imported_from,
                     foreign_key: {
                       to_table: :immunisation_imports
                     }
  end
end
