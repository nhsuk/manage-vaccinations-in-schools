# frozen_string_literal: true

class RemoveProcessedAtOnImports < ActiveRecord::Migration[7.2]
  def change
    remove_column :class_imports, :processed_at, :datetime
    remove_column :cohort_imports, :processed_at, :datetime
    remove_column :immunisation_imports, :processed_at, :datetime
  end
end
