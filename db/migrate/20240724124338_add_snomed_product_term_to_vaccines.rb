# frozen_string_literal: true

class AddSnomedProductTermToVaccines < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccines, :snomed_product_term, :string
  end
end
