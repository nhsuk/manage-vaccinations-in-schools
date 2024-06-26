# frozen_string_literal: true

class CreateOfflinePasswords < ActiveRecord::Migration[7.0]
  def change
    create_table :offline_passwords do |t|
      t.string :password, null: false

      t.timestamps
    end
  end
end
