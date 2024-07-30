# frozen_string_literal: true

class RenameVaccineSupplierToManufacturer < ActiveRecord::Migration[7.1]
  def change
    rename_column :vaccines, :supplier, :manufacturer
  end
end
