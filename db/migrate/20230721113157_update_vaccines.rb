# frozen_string_literal: true

class UpdateVaccines < ActiveRecord::Migration[7.0]
  def change
    change_table :vaccines, bulk: true do |t|
      t.rename :name, :type
      t.text :brand
      t.integer :method
    end
  end
end
