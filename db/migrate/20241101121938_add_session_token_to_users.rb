# frozen_string_literal: true

class AddSessionTokenToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :session_token, :string
  end
end
