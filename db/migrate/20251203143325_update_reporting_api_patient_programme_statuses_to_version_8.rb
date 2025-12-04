# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion8 < ActiveRecord::Migration[
  8.1
]
  def change
    replace_view :reporting_api_patient_programme_statuses,
                 version: 8,
                 revert_to_version: 7
  end
end
