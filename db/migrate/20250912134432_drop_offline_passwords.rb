# frozen_string_literal: true

class DropOfflinePasswords < ActiveRecord::Migration[8.0]
  def up
    drop_table :offline_passwords
  end
end
