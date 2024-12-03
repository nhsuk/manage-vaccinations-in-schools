# frozen_string_literal: true

class AddGIASCodesToLocations < ActiveRecord::Migration[7.2]
  def change
    change_table :locations, bulk: true do |t|
      t.integer :gias_local_authority_code
      t.integer :gias_establishment_number
    end
  end
end
