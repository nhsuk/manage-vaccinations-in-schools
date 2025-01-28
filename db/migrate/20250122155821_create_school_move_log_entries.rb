# frozen_string_literal: true

class CreateSchoolMoveLogEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :school_move_log_entries do |t|
      t.references :patient, foreign_key: true, null: false
      t.references :user, foreign_key: true

      t.references :school, foreign_key: { to_table: :locations }
      t.boolean :home_educated

      t.boolean :move_to_school

      t.datetime :created_at, null: false
    end
  end
end
