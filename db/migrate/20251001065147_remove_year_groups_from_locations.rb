# frozen_string_literal: true

class RemoveYearGroupsFromLocations < ActiveRecord::Migration[8.0]
  def change
    remove_column :locations,
                  :year_groups,
                  :integer,
                  array: true,
                  default: [],
                  null: false
  end
end
