class UpdateReportingAPITotalsToVersion2 < ActiveRecord::Migration[8.1]
  def change
    replace_view :reporting_api_totals,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
