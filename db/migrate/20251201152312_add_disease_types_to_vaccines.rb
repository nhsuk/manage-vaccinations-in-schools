# frozen_string_literal: true

class AddDiseaseTypesToVaccines < ActiveRecord::Migration[8.1]
  def change
    add_column :vaccines,
               :disease_types,
               :integer,
               array: true,
               default: [],
               null: false
  end
end
