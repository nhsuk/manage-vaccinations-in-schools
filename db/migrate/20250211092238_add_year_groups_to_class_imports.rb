# frozen_string_literal: true

class AddYearGroupsToClassImports < ActiveRecord::Migration[8.0]
  def change
    add_column :class_imports,
               :year_groups,
               :integer,
               array: true,
               default: [],
               null: false

    reversible do |dir|
      dir.up do
        ClassImport
          .includes(session: :programmes)
          .find_each do |class_import|
            year_groups = class_import.session.year_groups
            class_import.update!(year_groups:)
          end
      end
    end
  end
end
