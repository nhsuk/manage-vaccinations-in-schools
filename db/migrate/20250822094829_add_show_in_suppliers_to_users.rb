# frozen_string_literal: true

class AddShowInSuppliersToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :show_in_suppliers, :boolean, default: false, null: false
  end
end
