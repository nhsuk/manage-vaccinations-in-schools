# frozen_string_literal: true

class CreateVaccinationRecordChangesets < ActiveRecord::Migration[8.1]
  def change
    create_table :vaccination_record_changesets do |t|
      t.bigint :immunisation_import_id, null: false
      t.integer :row_number, null: false

      t.integer :status, null: false, default: 0

      t.bigint :patient_changeset_id
      t.bigint :patient_id

      # Programme stored as enum type used elsewhere in the app
      t.enum :programme_type, enum_type: :programme_type, null: false

      t.date :date_of_vaccination, null: false
      t.string :uuid

      t.jsonb :payload, null: false, default: {}
      # Avoid naming conflicts with ActiveModel#errors
      t.jsonb :serialized_errors, null: false, default: {}

      t.timestamps
    end

    add_index :vaccination_record_changesets, :status
    add_index :vaccination_record_changesets, :immunisation_import_id
    add_index :vaccination_record_changesets, :patient_changeset_id
    add_index :vaccination_record_changesets, :patient_id
    add_index :vaccination_record_changesets, :uuid

    add_foreign_key :vaccination_record_changesets,
                    :immunisation_imports,
                    column: :immunisation_import_id
    add_foreign_key :vaccination_record_changesets,
                    :patient_changesets,
                    column: :patient_changeset_id
    add_foreign_key :vaccination_record_changesets,
                    :patients,
                    column: :patient_id
  end
end
