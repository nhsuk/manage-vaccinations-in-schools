# frozen_string_literal: true

class CreateReportingAPITotals < ActiveRecord::Migration[8.1]
  def change
    create_view :reporting_api_totals, materialized: true

    add_index :reporting_api_totals,
              :id,
              unique: true,
              name: "ix_rapi_totals_id"
    add_index :reporting_api_totals,
              %i[team_id academic_year programme_type status],
              name: "ix_rapi_totals_team_year_prog_status"
    add_index :reporting_api_totals,
              :session_location_id,
              name: "ix_rapi_totals_session_loc"
    add_index :reporting_api_totals,
              :patient_year_group,
              name: "ix_rapi_totals_year_group"
  end
end
