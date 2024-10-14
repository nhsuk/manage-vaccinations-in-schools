# frozen_string_literal: true

class ChangeIndexOnUserProviderAndUid < ActiveRecord::Migration[7.2]
  def up
    remove_index :users, %i[provider uid]
    add_index :users, %i[provider uid], unique: true
  end

  def down
    remove_index :users, %i[provider uid]
    add_index :users, %i[provider uid]
  end
end
