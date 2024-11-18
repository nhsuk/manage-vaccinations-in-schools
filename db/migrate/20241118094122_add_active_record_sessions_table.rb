# frozen_string_literal: true

class AddActiveRecordSessionsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :active_record_sessions do |t|
      t.string :session_id, null: false
      t.jsonb :data
      t.timestamps
    end

    add_index :active_record_sessions, :session_id, unique: true
    add_index :active_record_sessions, :updated_at
  end
end
