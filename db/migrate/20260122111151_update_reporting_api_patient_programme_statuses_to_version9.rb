# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion9 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 9,
                revert_to_version: 8,
                materialized: true
  end
end
