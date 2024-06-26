# frozen_string_literal: true

class AddSupplierToVaccines < ActiveRecord::Migration[7.1]
  def change
    change_table :vaccines do |t|
      t.text :supplier
    end
  end
end
