# frozen_string_literal: true

class CreatePatientProgrammeStatus < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :patient_programme_statuses do |t|
      t.references :patient, null: false, foreign_key: { on_delete: :cascade }
      t.enum :programme_type, enum_type: :programme_type, null: false
      t.integer :academic_year, null: false

      t.integer :status, null: false, default: 0

      t.date :date
      t.integer :dose_sequence
      t.integer :vaccine_methods, array: true
      t.boolean :without_gelatine

      t.index %i[patient_id academic_year programme_type], unique: true
      t.index %i[academic_year patient_id]
      t.index :status
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
