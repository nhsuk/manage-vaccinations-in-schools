# frozen_string_literal: true

class UpdateReportingAPITotalsToVersion6 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
                version: 6,
                revert_to_version: 5,
                materialized: true
  end
end
