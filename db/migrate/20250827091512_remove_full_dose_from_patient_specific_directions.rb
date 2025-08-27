# frozen_string_literal: true

class RemoveFullDoseFromPatientSpecificDirections < ActiveRecord::Migration[8.0]
  def change
    remove_column :patient_specific_directions, :full_dose, :boolean
  end
end
