# frozen_string_literal: true

class AddIndexToChildrenNhsNumber < ActiveRecord::Migration[7.0]
  def change
    add_index :children, :nhs_number, unique: true
  end
end
