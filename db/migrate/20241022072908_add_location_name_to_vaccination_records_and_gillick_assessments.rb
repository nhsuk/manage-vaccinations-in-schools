# frozen_string_literal: true

class AddLocationNameToVaccinationRecordsAndGillickAssessments < ActiveRecord::Migration[
  7.2
]
  def change
    add_column :vaccination_records, :location_name, :string
    add_column :gillick_assessments, :location_name, :string
  end
end
