# frozen_string_literal: true

class CreateSessionProgrammes < ActiveRecord::Migration[8.0]
  def change
    rename_table :programmes_sessions, :session_programmes

    change_table :session_programmes do |t|
      t.primary_key :id
      t.index :session_id
      t.index :programme_id
    end
  end
end
