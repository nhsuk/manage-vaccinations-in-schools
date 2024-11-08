# frozen_string_literal: true

class RemoveRecordedAtFromVaccinationRecords < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up { VaccinationRecord.where(recorded_at: nil).delete_all }
    end

    remove_column :vaccination_records, :recorded_at, :datetime
  end
end
