# frozen_string_literal: true

class AddYearGroupsToClassImports < ActiveRecord::Migration[8.0]
  def change
    add_column :class_imports,
               :year_groups,
               :integer,
               array: true,
               default: [],
               null: false
  end
end
