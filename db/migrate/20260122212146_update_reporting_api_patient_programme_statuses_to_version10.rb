# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion10 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 10,
                revert_to_version: 9,
                materialized: true
  end
end
