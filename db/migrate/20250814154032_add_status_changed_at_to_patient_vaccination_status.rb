# frozen_string_literal: true

class AddStatusChangedAtToPatientVaccinationStatus < ActiveRecord::Migration[
  8.0
]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :patient_vaccination_statuses,
               :status_changed_at,
               :datetime,
               null: true

    change_column_null :patient_vaccination_statuses,
                       :status_changed_at,
                       false,
                       AcademicYear.first.to_academic_year_date_range.begin
    # rubocop:enable Rails/BulkChangeTable
  end
end
