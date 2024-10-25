# frozen_string_literal: true

class CreateNotifyLogEntry < ActiveRecord::Migration[7.2]
  def change
    create_table :notify_log_entries do |t|
      t.integer :type, null: false
      t.string :template_id, null: false
      t.string :recipient, null: false
      t.datetime :created_at, null: false

      t.references :consent_form, foreign_key: true
      t.references :patient, foreign_key: true
    end
  end
end
