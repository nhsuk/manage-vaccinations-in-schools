# frozen_string_literal: true

class AddNumberToBatch < ActiveRecord::Migration[8.1]
  def change
    add_column :batches, :number, :string
  end
end
