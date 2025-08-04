# frozen_string_literal: true

class AddAcademicYearToConsentForm < ActiveRecord::Migration[8.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.integer :academic_year
      t.index :academic_year
    end

    reversible do |dir|
      dir.up { ConsentForm.update_all(academic_year: AcademicYear.current) }
    end

    change_column_null :consent_forms, :academic_year, false
  end
end
