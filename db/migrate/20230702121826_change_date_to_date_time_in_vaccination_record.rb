# frozen_string_literal: true

class ChangeDateToDateTimeInVaccinationRecord < ActiveRecord::Migration[7.0]
  def up
    change_column :vaccination_records, :recorded_at, :datetime
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
