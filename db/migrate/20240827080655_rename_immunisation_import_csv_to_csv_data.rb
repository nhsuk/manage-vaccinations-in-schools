# frozen_string_literal: true

class RenameImmunisationImportCSVToCSVData < ActiveRecord::Migration[7.1]
  def change
    rename_column :immunisation_imports, :csv, :csv_data
  end
end
