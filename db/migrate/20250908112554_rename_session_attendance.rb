# frozen_string_literal: true

class RenameSessionAttendance < ActiveRecord::Migration[8.0]
  def change
    rename_table :session_attendances, :attendance_records
  end
end
