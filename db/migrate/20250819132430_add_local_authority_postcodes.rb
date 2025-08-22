# frozen_string_literal: true

class AddLocalAuthorityPostcodes < ActiveRecord::Migration[8.0]
  def change
    create_table :local_authority_postcodes,
                 id: false,
                 primary_key: %i[gss_code postcode] do |t|
      t.string :gss_code, null: false, index: true
      t.string :value, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
