# frozen_string_literal: true

class CreatePatientMergeLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :patient_merge_log_entries do |t|
      t.timestamps
      t.references :patient, null: false, foreign_key: true
      t.bigint :merged_patient_id, null: false
      t.string :merged_patient_name, null: false
      t.date :merged_patient_dob, null: false
      t.string :merged_patient_nhs_number, null: false
      t.references :user, null: true, foreign_key: true
    end
  end
end
