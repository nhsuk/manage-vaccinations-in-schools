# frozen_string_literal: true

class AddYearGroupsToLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :locations,
               :year_groups,
               :integer,
               array: true,
               default: [],
               null: false
  end
end
