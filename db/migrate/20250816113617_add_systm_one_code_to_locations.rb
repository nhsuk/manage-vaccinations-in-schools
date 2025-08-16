# frozen_string_literal: true

class AddSystmOneCodeToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :systm_one_code, :string
  end
end
