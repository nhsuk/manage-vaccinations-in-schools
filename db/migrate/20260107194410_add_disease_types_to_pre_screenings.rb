# frozen_string_literal: true

class AddDiseaseTypesToPreScreenings < ActiveRecord::Migration[8.1]
  def change
    add_column :pre_screenings,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
