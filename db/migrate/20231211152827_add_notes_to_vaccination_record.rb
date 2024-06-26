# frozen_string_literal: true

class AddNotesToVaccinationRecord < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccination_records, :notes, :text
  end
end
