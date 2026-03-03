# frozen_string_literal: true

class AddOutbreakToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :outbreak, :boolean, default: false
    Session.update_all(outbreak: false)
    change_column_null :sessions, :outbreak, false
  end
end
