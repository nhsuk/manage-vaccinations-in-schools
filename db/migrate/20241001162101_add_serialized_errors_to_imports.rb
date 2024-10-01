# frozen_string_literal: true

class AddSerializedErrorsToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :cohort_imports, :serialized_errors, :jsonb
    add_column :immunisation_imports, :serialized_errors, :jsonb
  end
end
