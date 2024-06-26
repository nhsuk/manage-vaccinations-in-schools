# frozen_string_literal: true

class CreateRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :registrations do |t|
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
