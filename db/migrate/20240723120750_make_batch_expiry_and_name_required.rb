# frozen_string_literal: true

class MakeBatchExpiryAndNameRequired < ActiveRecord::Migration[7.1]
  def change
    change_table :batches, bulk: true do |t|
      t.change_null :expiry, false
      t.change_null :name, false
    end
  end
end
