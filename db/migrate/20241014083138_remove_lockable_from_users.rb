# frozen_string_literal: true

class RemoveLockableFromUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.remove :failed_attempts, type: :integer, default: 0, null: false
      t.remove :locked_at, type: :datetime
      t.remove :unlock_token, type: :string
    end
  end
end
