# frozen_string_literal: true

class CreateArchiveReason < ActiveRecord::Migration[8.0]
  def change
    create_table :archive_reasons do |t|
      t.references :team, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.integer :type, null: false
      t.string :other_details, null: false, default: ""
      t.timestamps
      t.index %w[team_id patient_id], unique: true
    end
  end
end
