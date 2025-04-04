# frozen_string_literal: true

class CreatePatientSessionRegistrationStatus < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :patient_session_registration_statuses do |t|
      t.references :patient_session,
                   null: false,
                   index: {
                     unique: true
                   },
                   foreign_key: {
                     on_delete: :cascade
                   }
      t.integer :status, null: false, default: 0, index: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
