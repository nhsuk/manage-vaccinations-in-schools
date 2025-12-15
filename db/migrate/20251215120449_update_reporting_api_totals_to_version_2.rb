# frozen_string_literal: true

class UpdateReportingAPITotalsToVersion2 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
                version: 2,
                revert_to_version: 1,
                materialized: {
                  side_by_side: true
                }
  end
end
