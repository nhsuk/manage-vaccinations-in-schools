# frozen_string_literal: true

class AddBatchToVaccinationRecord < ActiveRecord::Migration[7.0]
  def change
    add_reference :vaccination_records, :batch, foreign_key: true
  end
end
