# frozen_string_literal: true

class AddYearGroupsToProgrammes < ActiveRecord::Migration[7.2]
  def change
    add_column :programmes, :year_groups, :integer, array: true, default: []
  end
end
