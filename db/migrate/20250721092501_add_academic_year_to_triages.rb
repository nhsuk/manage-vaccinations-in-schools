# frozen_string_literal: true

class AddAcademicYearToTriages < ActiveRecord::Migration[8.0]
  def change
    change_table :triage, bulk: true do |t|
      t.integer :academic_year
      t.index :academic_year
    end

    reversible do |dir|
      dir.up { Triage.update_all(academic_year: AcademicYear.current) }
    end

    change_column_null :triage, :academic_year, false
  end
end
