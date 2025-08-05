# frozen_string_literal: true

class AddAcademicYearToImports < ActiveRecord::Migration[8.0]
  def change
    add_column :class_imports, :academic_year, :integer
    add_column :cohort_imports, :academic_year, :integer
    add_column :school_moves, :academic_year, :integer

    academic_year = AcademicYear.current

    reversible do |direction|
      direction.up do
        ClassImport.update_all(academic_year:)
        CohortImport.update_all(academic_year:)
        SchoolMove.update_all(academic_year:)
      end
    end

    change_column_null :class_imports, :academic_year, false
    change_column_null :cohort_imports, :academic_year, false
    change_column_null :school_moves, :academic_year, false
  end
end
