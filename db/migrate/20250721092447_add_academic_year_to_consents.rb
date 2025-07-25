# frozen_string_literal: true

class AddAcademicYearToConsents < ActiveRecord::Migration[8.0]
  def up
    add_column :consents, :academic_year, :integer

    academic_year = Date.current.academic_year
    Consent.update_all(academic_year:)

    change_column_null :consents, :academic_year, false
    add_index :consents, :academic_year
  end

  def down
    remove_index :consents, :academic_year
    remove_column :consents, :academic_year
  end
end
