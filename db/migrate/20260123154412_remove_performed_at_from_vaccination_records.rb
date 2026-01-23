# frozen_string_literal: true

class RemovePerformedAtFromVaccinationRecords < ActiveRecord::Migration[8.1]
  def change
    remove_column :vaccination_records, :performed_at, :datetime
  end
end
