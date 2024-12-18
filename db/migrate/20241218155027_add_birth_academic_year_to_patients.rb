# frozen_string_literal: true

class AddBirthAcademicYearToPatients < ActiveRecord::Migration[8.0]
  def up
    add_column :patients, :birth_academic_year, :integer
    Patient.find_each do |patient|
      patient.update_column(
        :birth_academic_year,
        patient.date_of_birth.academic_year
      )
    end
    change_column_null :patients, :birth_academic_year, false
  end

  def down
    remove_column :patients, :birth_academic_year
  end
end
