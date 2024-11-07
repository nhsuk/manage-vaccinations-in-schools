# frozen_string_literal: true

class AddFallbackRoleToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :fallback_role, :integer, default: 0, null: false
  end
end
