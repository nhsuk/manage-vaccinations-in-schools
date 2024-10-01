# frozen_string_literal: true

class CreateSessionNotifications < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :session_notifications do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.date :session_date, null: false
      t.datetime :sent_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.index %i[patient_id session_id session_date]
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
