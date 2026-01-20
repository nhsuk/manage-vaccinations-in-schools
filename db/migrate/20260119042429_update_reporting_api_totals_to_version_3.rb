class UpdateReportingAPITotalsToVersion3 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
      version: 3,
      revert_to_version: 2,
      materialized: true
  end
end
