# frozen_string_literal: true

class AddIndexOnVaccinationRecordsUuid < ActiveRecord::Migration[7.2]
  def change
    add_index :vaccination_records, :uuid, unique: true
  end
end
