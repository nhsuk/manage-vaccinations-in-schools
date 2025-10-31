# frozen_string_literal: true

class DropReportingAPIVaccinationEvents < ActiveRecord::Migration[8.0]
  def up
    drop_table :reporting_api_vaccination_events
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
