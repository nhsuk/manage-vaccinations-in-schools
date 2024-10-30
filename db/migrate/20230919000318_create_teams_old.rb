# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.text :name, null: false, index: { unique: true }

      t.timestamps null: false
    end
  end
end
