# frozen_string_literal: true

class CreatePatientConsentStatus < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :patient_consent_statuses do |t|
      t.references :patient,
                   null: false,
                   index: false,
                   foreign_key: {
                     on_delete: :cascade
                   }
      t.references :programme, null: false, index: false, foreign_key: true
      t.integer :status, null: false, default: 0, index: true
      t.boolean :health_answers_require_follow_up, null: false, default: false
      t.index %i[patient_id programme_id], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
