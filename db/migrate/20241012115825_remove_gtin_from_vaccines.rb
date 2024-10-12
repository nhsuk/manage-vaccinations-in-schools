# frozen_string_literal: true

class RemoveGtinFromVaccines < ActiveRecord::Migration[7.2]
  def change
    remove_column :vaccines, :gtin, :string
  end
end
