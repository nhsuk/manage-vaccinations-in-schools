# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion7 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 7,
                revert_to_version: 6,
                materialized: true
  end
end
