# frozen_string_literal: true

class AddRegistrationAcademicYearToPatients < ActiveRecord::Migration[8.0]
  def change
    add_column :patients, :registration_academic_year, :integer

    reversible do |dir|
      dir.up do
        Patient
          .where.not(registration: [nil, ""])
          .update_all(registration_academic_year: AcademicYear.current)
      end
    end
  end
end
