# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion3 < ActiveRecord::Migration[
  8.0
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 3,
                revert_to_version: 2,
                materialized: true
  end
end
