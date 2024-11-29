# frozen_string_literal: true

class RenameCSVImportableRecordedAt < ActiveRecord::Migration[7.2]
  def change
    rename_column :class_imports, :recorded_at, :processed_at
    rename_column :cohort_imports, :recorded_at, :processed_at
    rename_column :immunisation_imports, :recorded_at, :processed_at
  end
end
