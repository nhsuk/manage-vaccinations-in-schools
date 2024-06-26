# frozen_string_literal: true

class AddRegistrationToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :registration, :string
  end
end
