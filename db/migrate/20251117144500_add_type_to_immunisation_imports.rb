# frozen_string_literal: true

class AddTypeToImmunisationImports < ActiveRecord::Migration[7.2]
  def change
    add_column :immunisation_imports, :type, :integer, default: 0, null: false
  end
end
