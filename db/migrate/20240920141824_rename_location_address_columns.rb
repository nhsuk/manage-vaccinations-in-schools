# frozen_string_literal: true

class RenameLocationAddressColumns < ActiveRecord::Migration[7.2]
  def change
    change_table :locations, bulk: true do |t|
      t.remove :county, type: :text
      t.rename :address, :address_line_1
      t.rename :locality, :address_line_2
      t.rename :postcode, :address_postcode
      t.rename :town, :address_town
    end
  end
end
