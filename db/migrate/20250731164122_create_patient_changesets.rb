# frozen_string_literal: true

class CreatePatientChangesets < ActiveRecord::Migration[8.0]
  def change
    create_table :patient_changesets do |t|
      t.references :patient, null: true, foreign_key: true, index: true
      t.jsonb :pending_changes, null: false, default: {}
      t.belongs_to :import, polymorphic: true, null: false
      t.integer :row_number, null: false
      t.integer :status, null: false, default: 0, index: true
      t.references :school, foreign_key: { to_table: :locations }, index: false

      t.timestamps
    end
  end
end
