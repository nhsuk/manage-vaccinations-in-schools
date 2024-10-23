# frozen_string_literal: true

class RemoveDefaultOnUserEmail < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :email, from: "", to: nil
  end
end
