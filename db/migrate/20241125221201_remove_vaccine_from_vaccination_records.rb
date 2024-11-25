# frozen_string_literal: true

class RemoveVaccineFromVaccinationRecords < ActiveRecord::Migration[7.2]
  def change
    remove_reference :vaccination_records,
                     :vaccine,
                     null: true,
                     foreign_key: true
  end
end
