# frozen_string_literal: true

class RemoveDiseaseTypesEnumFromVaccines < ActiveRecord::Migration[8.1]
  def change
    remove_column :vaccines,
                  :disease_types_enum,
                  :enum,
                  enum_type: :disease_type,
                  array: true,
                  null: false
  end
end
