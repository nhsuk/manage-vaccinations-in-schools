# frozen_string_literal: true

class AddDraftFieldToSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :sessions, :draft, :boolean, default: false
  end
end
