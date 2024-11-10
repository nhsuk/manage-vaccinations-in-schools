# frozen_string_literal: true

class CreateSessionAttendance < ActiveRecord::Migration[7.2]
  def change
    create_table :session_attendances do |t|
      t.references :patient_session, null: false, foreign_key: true
      t.references :session_date, null: false, foreign_key: true
      t.boolean :attending, null: false

      t.timestamps
    end
  end
end
