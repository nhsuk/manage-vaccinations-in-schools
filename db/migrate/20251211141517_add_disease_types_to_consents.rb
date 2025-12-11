# frozen_string_literal: true

class AddDiseaseTypesToConsents < ActiveRecord::Migration[8.1]
  def change
    add_column :consents,
               :disease_types,
               :integer,
               array: true,
               default: [],
               null: true
  end
end
