# frozen_string_literal: true

class AddSessionDateIdToPreScreenings < ActiveRecord::Migration[6.1]
  def up
    add_reference :pre_screenings, :session_date, foreign_key: true, null: true

    PreScreening.find_each do |pre_screening|
      session = pre_screening.patient_session.session
      matching_session_date =
        session.session_dates.find_by(value: pre_screening.created_at.to_date)

      if matching_session_date.present?
        pre_screening.update_column(:session_date_id, matching_session_date.id)
      else
        raise ActiveRecord::IrreversibleMigration,
              "No matching session_date found for PreScreening id: #{pre_screening.id}"
      end
    end

    change_column_null :pre_screenings, :session_date_id, false
  end

  def down
    remove_reference :pre_screenings, :session_date
  end
end
