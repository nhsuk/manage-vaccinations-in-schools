# frozen_string_literal: true

class AddGIASYearGroupsToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations,
               :gias_year_groups,
               :integer,
               array: true,
               default: [],
               null: false

    reversible do |direction|
      direction.up do
        execute "UPDATE locations SET gias_year_groups = year_groups"
      end
    end
  end
end
