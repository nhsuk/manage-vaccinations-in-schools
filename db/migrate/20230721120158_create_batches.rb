# frozen_string_literal: true

class CreateBatches < ActiveRecord::Migration[7.0]
  def change
    create_table :batches do |t|
      t.string :name
      t.date :expiry
      t.references :vaccine, null: false, foreign_key: true

      t.timestamps
    end
  end
end
