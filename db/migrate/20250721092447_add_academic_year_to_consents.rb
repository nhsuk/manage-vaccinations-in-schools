# frozen_string_literal: true

class AddAcademicYearToConsents < ActiveRecord::Migration[8.0]
  def change
    change_table :consents, bulk: true do |t|
      t.integer :academic_year
      t.index :academic_year
    end

    reversible do |dir|
      dir.up { Consent.update_all(academic_year: AcademicYear.current) }
    end

    change_column_null :consents, :academic_year, false
  end
end
