# frozen_string_literal: true

class AddUrnToLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :urn, :string
  end
end
