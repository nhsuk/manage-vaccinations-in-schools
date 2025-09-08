# frozen_string_literal: true

class RemoveSessionFromAttendanceRecord < ActiveRecord::Migration[8.0]
  def up
    change_table :attendance_records, bulk: true do |t|
      t.date :date
      t.references :location, foreign_key: true
    end

    execute <<-SQL
      UPDATE attendance_records
      SET location_id = sessions.location_id, date = session_dates.value
      FROM session_dates
        JOIN sessions ON sessions.id = session_dates.session_id
      WHERE session_dates.id = attendance_records.session_date_id
    SQL

    change_table :attendance_records, bulk: true do |t|
      t.change_null :date, false
      t.change_null :location_id, false
    end

    remove_column :attendance_records, :session_date_id

    execute <<-SQL
      DELETE FROM attendance_records a
      USING attendance_records b 
      WHERE a.id < b.id
        AND a.patient_id = b.patient_id
        AND a.location_id = b.location_id
        AND a.date = b.date
    SQL

    add_index :attendance_records, %i[patient_id location_id date], unique: true
  end
end
