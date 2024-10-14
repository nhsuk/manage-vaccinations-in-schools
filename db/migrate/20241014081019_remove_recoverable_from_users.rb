# frozen_string_literal: true

class RemoveRecoverableFromUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.remove :reset_password_sent_at, type: :datetime
      t.remove :reset_password_token, type: :string
    end
  end
end
