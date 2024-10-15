# frozen_string_literal: true

class RenameParentNameToFullName < ActiveRecord::Migration[7.2]
  def change
    rename_column :parents, :name, :full_name
    rename_column :consent_forms, :parent_name, :parent_full_name
  end
end
