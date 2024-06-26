# frozen_string_literal: true

class ChangeNhsNumberFromBigIntToString < ActiveRecord::Migration[7.1]
  def up
    change_column :patients, :nhs_number, :string
  end

  def down
    change_column :patients, :nhs_number, :bigint
  end
end
