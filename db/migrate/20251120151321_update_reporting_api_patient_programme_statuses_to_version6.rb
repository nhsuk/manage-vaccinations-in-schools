# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion6 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 6,
                revert_to_version: 5,
                materialized: true
  end
end
