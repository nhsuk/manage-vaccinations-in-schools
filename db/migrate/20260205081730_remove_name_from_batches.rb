# frozen_string_literal: true

class RemoveNameFromBatches < ActiveRecord::Migration[8.1]
  def change
    remove_column :batches, :name, :string
  end
end
