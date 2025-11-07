# frozen_string_literal: true

class UpdateReportingAPIPatientProgrammeStatusesToVersion3 < ActiveRecord::Migration[
  8.0
]
  def change
    update_view :reporting_api_patient_programme_statuses,
                version: 3,
                revert_to_version: 2,
                materialized: true

    add_index :vaccination_records,
              %i[patient_id programme_id outcome],
              where: "discarded_at IS NULL",
              name: "idx_vr_fast_lookup",
              if_not_exists: true
  end
end
