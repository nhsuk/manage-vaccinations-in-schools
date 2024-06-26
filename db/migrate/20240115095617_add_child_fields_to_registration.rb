# frozen_string_literal: true

class AddChildFieldsToRegistration < ActiveRecord::Migration[7.1]
  def change
    change_table :registrations, bulk: true do |t|
      t.string :first_name
      t.string :last_name
      t.boolean :use_common_name
      t.string :common_name
      t.date :date_of_birth
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_town
      t.string :address_postcode
      t.string :nhs_number
    end
  end
end
