# frozen_string_literal: true

class AddPerformedByNameToVaccinationRecords < ActiveRecord::Migration[7.1]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.string :performed_by_given_name
      t.string :performed_by_family_name
    end
  end
end
