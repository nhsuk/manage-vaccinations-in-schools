# frozen_string_literal: true

class ChangeClassImportSerializedErrorsToJsonb < ActiveRecord::Migration[8.0]
  def up
    change_column :class_imports,
                  :serialized_errors,
                  :jsonb,
                  using: "serialized_errors::jsonb"
  end

  def down
    change_column :class_imports,
                  :serialized_errors,
                  :json,
                  using: "serialized_errors::json"
  end
end
