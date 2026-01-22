# frozen_string_literal: true

class AddPerformedAtDateAndTimeToVaccinationRecords < ActiveRecord::Migration[
  8.1
]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.date :performed_at_date
      t.time :performed_at_time
    end
  end
end
