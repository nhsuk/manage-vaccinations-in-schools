# frozen_string_literal: true

class MakePatientColumnsRequired < ActiveRecord::Migration[7.2]
  def change
    change_table :patients, bulk: true do |t|
      t.change_null :first_name, false
      t.change_null :last_name, false
      t.change_null :date_of_birth, false
      t.change_null :address_postcode, false
    end
  end
end
