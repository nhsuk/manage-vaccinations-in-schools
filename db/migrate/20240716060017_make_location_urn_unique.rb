# frozen_string_literal: true

class MakeLocationUrnUnique < ActiveRecord::Migration[7.1]
  def change
    add_index :locations, :urn, unique: true
  end
end
