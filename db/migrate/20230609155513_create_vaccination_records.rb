# frozen_string_literal: true

class CreateVaccinationRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :vaccination_records do |t|
      t.references :patient_session, null: false, foreign_key: true
      t.date :administered_at

      t.timestamps
    end
  end
end
