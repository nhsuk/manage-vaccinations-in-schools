# frozen_string_literal: true

class AddSiteToLocations < ActiveRecord::Migration[8.0]
  def change
    change_table :locations, bulk: true do |t|
      t.string :site
      t.remove_index :urn, unique: true
      t.index %i[urn site], unique: true
    end
  end
end
