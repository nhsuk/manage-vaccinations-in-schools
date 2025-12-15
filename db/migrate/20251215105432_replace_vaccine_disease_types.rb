# frozen_string_literal: true

class ReplaceVaccineDiseaseTypes < ActiveRecord::Migration[8.1]
  def change
    change_table :vaccines, bulk: true do |t|
      t.remove :disease_types,
               type: :integer,
               array: true,
               null: true,
               default: []
      t.enum :disease_types,
             enum_type: :disease_type,
             array: true,
             null: false,
             default: []
      t.change_null :disease_types_enum, true
    end

    reversible do |dir|
      dir.up do
        execute "UPDATE vaccines SET disease_types = disease_types_enum"
      end
    end

    change_column_default :vaccines, :disease_types_enum, from: [], to: nil
  end
end
