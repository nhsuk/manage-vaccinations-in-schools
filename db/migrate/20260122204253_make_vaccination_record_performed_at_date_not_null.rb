# frozen_string_literal: true

class MakeVaccinationRecordPerformedAtDateNotNull < ActiveRecord::Migration[8.1]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.change_null :performed_at_date, false
      t.change_null :performed_at, true
    end
  end
end
