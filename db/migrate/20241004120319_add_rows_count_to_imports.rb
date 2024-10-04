# frozen_string_literal: true

class AddRowsCountToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :class_imports, :rows_count, :integer
    add_column :cohort_imports, :rows_count, :integer
    add_column :immunisation_imports, :rows_count, :integer
  end
end
