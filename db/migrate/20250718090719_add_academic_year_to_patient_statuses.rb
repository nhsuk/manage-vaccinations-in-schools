# frozen_string_literal: true

class AddAcademicYearToPatientStatuses < ActiveRecord::Migration[8.0]
  TABLES = %i[
    patient_consent_statuses
    patient_triage_statuses
    patient_vaccination_statuses
  ].freeze

  def up
    TABLES.each { |table| add_column table, :academic_year, :integer }

    academic_year = Date.current.academic_year

    Patient::ConsentStatus.update_all(academic_year:)
    Patient::TriageStatus.update_all(academic_year:)
    Patient::VaccinationStatus.update_all(academic_year:)

    TABLES.each do |table|
      change_table table, bulk: true do |t|
        t.change_null :academic_year, false
        t.remove_index %i[patient_id programme_id]
        t.index %i[patient_id programme_id academic_year], unique: true
      end
    end
  end

  def down
    TABLES.each { |table| remove_column table, :academic_year }
  end
end
