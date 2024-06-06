class AddProviderUidIndexToUser < ActiveRecord::Migration[7.1]
  def change
    add_index :users, %i[provider uid]
  end
end
