# frozen_string_literal: true

class AddAcademicYearToPatientSpecificDirections < ActiveRecord::Migration[8.0]
  def change
    change_table :patient_specific_directions, bulk: true do |t|
      t.integer :academic_year
      t.index :academic_year
    end

    reversible do |dir|
      dir.up do
        PatientSpecificDirection.update_all(academic_year: AcademicYear.current)
      end
    end

    change_column_null :patient_specific_directions, :academic_year, false
  end
end
