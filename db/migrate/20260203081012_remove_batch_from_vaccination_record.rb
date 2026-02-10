# frozen_string_literal: true

class RemoveBatchFromVaccinationRecord < ActiveRecord::Migration[8.1]
  def change
    remove_reference :vaccination_records, :batch, foreign_key: true
  end
end
