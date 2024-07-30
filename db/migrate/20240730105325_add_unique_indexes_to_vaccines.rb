# frozen_string_literal: true

class AddUniqueIndexesToVaccines < ActiveRecord::Migration[7.1]
  def change
    change_table :vaccines, bulk: true do |t|
      t.index :gtin, unique: true
      t.index :snomed_product_code, unique: true
      t.index :snomed_product_term, unique: true
      t.index %i[supplier brand], unique: true
    end
  end
end
