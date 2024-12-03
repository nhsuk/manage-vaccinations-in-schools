# frozen_string_literal: true

class AddUniqueIndexToSessionAttendance < ActiveRecord::Migration[7.2]
  def change
    add_index :session_attendances,
              %i[patient_session_id session_date_id],
              unique: true
  end
end
