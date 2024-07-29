# frozen_string_literal: true

class AddUuidToVaccinationRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccination_records,
               :uuid,
               :uuid,
               default: "gen_random_uuid()",
               null: false
  end
end
