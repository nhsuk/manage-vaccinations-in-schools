# frozen_string_literal: true

class AddStatusToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :cohort_imports, :status, :integer, default: 0, null: false
    add_column :immunisation_imports, :status, :integer, default: 0, null: false
  end
end
