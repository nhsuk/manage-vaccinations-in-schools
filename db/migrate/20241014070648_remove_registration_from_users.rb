# frozen_string_literal: true

class RemoveRegistrationFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :registration, :string
  end
end
