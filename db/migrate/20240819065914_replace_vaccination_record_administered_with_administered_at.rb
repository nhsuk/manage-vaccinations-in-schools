# frozen_string_literal: true

class ReplaceVaccinationRecordAdministeredWithAdministeredAt < ActiveRecord::Migration[
  7.1
]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.datetime :administered_at
      t.remove :administered, type: :boolean
    end
  end
end
