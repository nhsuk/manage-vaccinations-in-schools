# frozen_string_literal: true

class EnsureLocationUrnsAreUnique < ActiveRecord::Migration[8.0]
  def change
    add_index :locations, :urn, unique: true, where: "site IS NULL"
    add_index :locations, :systm_one_code, unique: true
  end
end
