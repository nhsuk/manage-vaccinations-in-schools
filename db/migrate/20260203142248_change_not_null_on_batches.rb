# frozen_string_literal: true

class ChangeNotNullOnBatches < ActiveRecord::Migration[8.1]
  def change
    change_table :batches, bulk: true do |t|
      t.change_null :number, false
      t.change_null :name, true
    end
  end
end
