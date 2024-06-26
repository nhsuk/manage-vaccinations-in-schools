# frozen_string_literal: true

class ChangeSchoolsUrnToBigintAndIndexed < ActiveRecord::Migration[7.0]
  def up
    change_column :schools, :urn, :integer
    add_index :schools, :urn, unique: true
  end

  def down
    remove_index :schools, :urn, unique: true
    change_column :schools, :urn, :decimal
  end
end
