# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion2 < ActiveRecord::Migration[
  8.0
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 2,
                revert_to_version: 1,
                materialized: true
  end
end
