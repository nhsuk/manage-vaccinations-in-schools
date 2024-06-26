# frozen_string_literal: true

class ChangeNhsNumberToInteger < ActiveRecord::Migration[7.0]
  def up
    change_column :children, :nhs_number, :bigint
  end

  def down
    change_column :children, :nhs_number, :decimal
  end
end
