# frozen_string_literal: true

class AddDatesToSessions < ActiveRecord::Migration[8.1]
  def change
    change_table :sessions, bulk: true do |t|
      t.date :dates, array: true
      t.index :dates, using: :gin
    end
  end
end
