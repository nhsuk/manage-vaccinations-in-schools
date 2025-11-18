# frozen_string_literal: true

class AddNivsNameToVaccines < ActiveRecord::Migration[8.1]
  def change
    add_column :vaccines, :nivs_name, :string
  end
end
