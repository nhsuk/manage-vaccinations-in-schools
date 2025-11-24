# frozen_string_literal: true

class AddContainsGelatineToVaccines < ActiveRecord::Migration[8.0]
  def change
    add_column :vaccines, :contains_gelatine, :boolean

    reversible do |direction|
      direction.up do
        Vaccine.find_each do |vaccine|
          contains_gelatine = vaccine.programme.flu? && vaccine.nasal?
          vaccine.update_columns(contains_gelatine:)
        end
      end
    end

    change_column_null :vaccines, :contains_gelatine, false
  end
end
