# frozen_string_literal: true

class AddSnomedProductCodeToVaccines < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccines, :snomed_product_code, :string
  end
end
