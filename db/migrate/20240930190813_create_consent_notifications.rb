# frozen_string_literal: true

class CreateConsentNotifications < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :consent_notifications do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :programme, null: false, foreign_key: true
      t.boolean :reminder, null: false
      t.datetime :sent_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.index %i[patient_id programme_id]
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
