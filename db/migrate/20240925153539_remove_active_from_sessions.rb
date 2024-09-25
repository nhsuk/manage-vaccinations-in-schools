# frozen_string_literal: true

class RemoveActiveFromSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :sessions, :active, :boolean, null: false, default: false
  end
end
