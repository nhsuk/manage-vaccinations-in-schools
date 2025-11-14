# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion4 < ActiveRecord::Migration[
  8.1
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 4,
                revert_to_version: 3,
                materialized: true
  end
end
