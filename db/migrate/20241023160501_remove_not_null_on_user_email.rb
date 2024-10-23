# frozen_string_literal: true

class RemoveNotNullOnUserEmail < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :email, true
  end
end
