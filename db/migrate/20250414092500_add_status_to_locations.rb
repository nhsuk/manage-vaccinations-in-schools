# frozen_string_literal: true

class AddStatusToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :status, :integer, default: 0, null: false
  end
end
