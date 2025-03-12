# frozen_string_literal: true

class AddProgrammeToPreScreenings < ActiveRecord::Migration[8.0]
  def up
    add_reference :pre_screenings, :programme, foreign_key: true

    PreScreening
      .includes(patient_session: { session: :programmes })
      .find_each do |pre_screening|
        pre_screening.update_column(
          :programme_id,
          pre_screening.patient_session.programmes.first.id
        )
      end

    change_column_null :pre_screenings, :programme_id, false
  end

  def down
    remove_reference :pre_screenings, :programme
  end
end
