# frozen_string_literal: true

class AddAddressFieldsToPatient < ActiveRecord::Migration[7.1]
  def change
    change_table :patients, bulk: true do |t|
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_town
      t.string :address_postcode
    end
  end
end
