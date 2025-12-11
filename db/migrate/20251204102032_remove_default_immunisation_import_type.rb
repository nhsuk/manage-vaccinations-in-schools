# frozen_string_literal: true

class RemoveDefaultImmunisationImportType < ActiveRecord::Migration[8.1]
  def change
    change_column_default :immunisation_imports, :type, from: 0, to: nil
  end
end
