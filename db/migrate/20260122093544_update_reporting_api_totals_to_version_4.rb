class UpdateReportingAPITotalsToVersion4 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
      version: 4,
      revert_to_version: 3,
      materialized: true
  end
end
