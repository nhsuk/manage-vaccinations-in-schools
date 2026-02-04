# frozen_string_literal: true

class UpdateReportingAPITotalsToVersion8 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
                version: 8,
                revert_to_version: 7,
                materialized: true
  end
end
