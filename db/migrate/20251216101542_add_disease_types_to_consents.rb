# frozen_string_literal: true

class AddDiseaseTypesToConsents < ActiveRecord::Migration[8.1]
  def change
    add_column :consents,
               :disease_types,
               :enum,
               enum_type: :disease_type,
               array: true
  end
end
