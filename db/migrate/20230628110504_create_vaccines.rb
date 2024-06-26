# frozen_string_literal: true

class CreateVaccines < ActiveRecord::Migration[7.0]
  def change
    create_table :vaccines do |t|
      t.string :name

      t.timestamps
    end
    add_index :vaccines, :name, unique: true
  end
end
