# frozen_string_literal: true

class MakeLocationUrnOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :locations, :urn, true
  end
end
