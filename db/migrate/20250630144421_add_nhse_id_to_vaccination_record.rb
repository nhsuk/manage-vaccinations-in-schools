# frozen_string_literal: true

class AddNHSEIdToVaccinationRecord < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccination_records, :nhse_id, :string, null: true
  end
end
