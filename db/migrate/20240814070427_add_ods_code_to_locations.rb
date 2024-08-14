# frozen_string_literal: true

class AddODSCodeToLocations < ActiveRecord::Migration[7.1]
  def change
    change_table :locations, bulk: true do |t|
      t.string :ods_code
      t.index :ods_code, unique: true
    end
  end
end
