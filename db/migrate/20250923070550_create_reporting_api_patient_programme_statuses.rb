# frozen_string_literal: true

class CreateReportingAPIPatientProgrammeStatuses < ActiveRecord::Migration[8.0]
  def change
    create_view :reporting_api_patient_programme_statuses, materialized: true

    add_index :reporting_api_patient_programme_statuses, :id,
              unique: true, name: "ix_rapi_pps_id"

    add_index :reporting_api_patient_programme_statuses,
              [:programme_id, :team_id, :academic_year],
              name: "ix_rapi_pps_prog_team_year"

    add_index :reporting_api_patient_programme_statuses,
              [:academic_year, :programme_type],
              name: "ix_rapi_pps_year_prog_type"

    add_index :reporting_api_patient_programme_statuses,
              [:team_id, :academic_year],
              name: "ix_rapi_pps_team_year"

    add_index :reporting_api_patient_programme_statuses,
              [:patient_school_local_authority_code, :programme_type],
              name: "ix_rapi_pps_school_la_prog"

    add_index :reporting_api_patient_programme_statuses,
              [:organisation_id, :academic_year, :programme_type],
              name: "ix_rapi_pps_org_year_prog"
  end
end
