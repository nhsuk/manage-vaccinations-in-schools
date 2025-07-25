# frozen_string_literal: true

class AddAcademicYearToPatientSpecificDirections < ActiveRecord::Migration[8.0]
  def up
    add_column :patient_specific_directions, :academic_year, :integer

    academic_year = Date.current.academic_year
    PatientSpecificDirection.update_all(academic_year:)

    change_column_null :patient_specific_directions, :academic_year, false
    add_index :patient_specific_directions, :academic_year
  end

  def down
    remove_index :patient_specific_directions, :academic_year
    remove_column :patient_specific_directions, :academic_year
  end
end
