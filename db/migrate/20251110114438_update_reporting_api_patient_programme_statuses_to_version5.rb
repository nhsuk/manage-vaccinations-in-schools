# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion5 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 5,
                revert_to_version: 4,
                materialized: true
  end
end
