# frozen_string_literal: true

class AddClosedAtToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :closed_at, :datetime
  end
end
