# frozen_string_literal: true

class AddVaccineToVaccinationRecord < ActiveRecord::Migration[7.1]
  def change
    add_reference :vaccination_records, :vaccine, foreign_key: true
  end
end
