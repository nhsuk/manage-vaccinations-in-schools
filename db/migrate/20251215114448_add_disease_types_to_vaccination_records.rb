# frozen_string_literal: true

class AddDiseaseTypesToVaccinationRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :vaccination_records,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
