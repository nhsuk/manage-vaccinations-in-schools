# frozen_string_literal: true

class MakeLocationUrnRequired < ActiveRecord::Migration[7.1]
  def change
    change_column_null :locations, :urn, false
  end
end
