# frozen_string_literal: true

class AddResetPasswordTokenToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.index :reset_password_token, unique: true
    end
  end
end
