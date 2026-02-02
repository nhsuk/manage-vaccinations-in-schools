# frozen_string_literal: true

class UpdateReportingAPITotalsToVersion5 < ActiveRecord::Migration[8.1]
  def change
    update_view :reporting_api_totals,
                version: 5,
                revert_to_version: 4,
                materialized: true
  end
end
