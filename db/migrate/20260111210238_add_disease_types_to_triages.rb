# frozen_string_literal: true

class AddDiseaseTypesToTriages < ActiveRecord::Migration[8.1]
  def change
    add_column :triages,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
