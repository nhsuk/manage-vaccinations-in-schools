# frozen_string_literal: true

class CreateAccessLogEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :access_log_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.integer :controller, null: false
      t.integer :action, null: false
      t.timestamps
    end
  end
end
