# frozen_string_literal: true

class AddAcademicYearToConsentForm < ActiveRecord::Migration[8.0]
  def up
    add_column :consent_forms, :academic_year, :integer

    academic_year = Date.current.academic_year
    ConsentForm.update_all(academic_year:)

    change_column_null :consent_forms, :academic_year, false
    add_index :consent_forms, :academic_year
  end

  def down
    remove_index :consent_forms, :academic_year
    remove_column :consent_forms, :academic_year
  end
end
