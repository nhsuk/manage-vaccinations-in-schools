# frozen_string_literal: true

class AddDiseaseTypesEnumToVaccines < ActiveRecord::Migration[8.1]
  MAPPING = {
    influenza: 0,
    human_papillomavirus: 1,
    meningitis_a: 2,
    meningitis_c: 3,
    meningitis_w: 4,
    meningitis_y: 5,
    polio: 6,
    tetanus: 7,
    diphtheria: 8,
    measles: 9,
    mumps: 10,
    rubella: 11,
    varicella: 12
  }.freeze

  def change
    add_column :vaccines,
               :disease_types_enum,
               :enum,
               enum_type: :disease_type,
               array: true,
               null: false,
               default: []

    reversible do |dir|
      dir.up do
        Vaccine.find_each do |vaccine|
          disease_types_enum =
            vaccine.attributes.fetch("disease_types").map { MAPPING.key(it) }
          vaccine.update_columns(disease_types_enum:)
        end
      end
    end

    change_column_default :vaccines, :disease_types_enum, from: [], to: nil
  end
end
