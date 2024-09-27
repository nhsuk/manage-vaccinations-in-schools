# frozen_string_literal: true

class RemoveTypeFromVaccines < ActiveRecord::Migration[7.2]
  def change
    remove_column :vaccines, :type, :string, null: false
  end
end
