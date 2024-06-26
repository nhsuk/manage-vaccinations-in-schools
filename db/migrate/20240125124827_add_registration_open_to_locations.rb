# frozen_string_literal: true

class AddRegistrationOpenToLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :registration_open, :boolean, default: false
  end
end
