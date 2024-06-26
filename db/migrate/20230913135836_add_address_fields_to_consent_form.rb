# frozen_string_literal: true

class AddAddressFieldsToConsentForm < ActiveRecord::Migration[7.0]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_town
      t.string :address_postcode
    end
  end
end
