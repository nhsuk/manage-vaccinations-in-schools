# frozen_string_literal: true

class UpdateReportingAPITotalsToVersion7 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
                version: 7,
                revert_to_version: 6,
                materialized: true
  end
end
