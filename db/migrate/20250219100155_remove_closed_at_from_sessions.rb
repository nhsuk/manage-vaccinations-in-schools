# frozen_string_literal: true

class RemoveClosedAtFromSessions < ActiveRecord::Migration[8.0]
  def change
    remove_column :sessions, :closed_at, :datetime
  end
end
