# frozen_string_literal: true

class AddAcademicYearToTriages < ActiveRecord::Migration[8.0]
  def up
    add_column :triage, :academic_year, :integer

    academic_year = Date.current.academic_year
    Triage.update_all(academic_year:)

    change_column_null :triage, :academic_year, false
    add_index :triage, :academic_year
  end

  def down
    remove_index :triage, :academic_year
    remove_column :triage, :academic_year
  end
end
