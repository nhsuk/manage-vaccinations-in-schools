# frozen_string_literal: true

class AddDiscontinuedToVaccines < ActiveRecord::Migration[7.1]
  def change
    add_column :vaccines, :discontinued, :boolean, default: false, null: false
  end
end
