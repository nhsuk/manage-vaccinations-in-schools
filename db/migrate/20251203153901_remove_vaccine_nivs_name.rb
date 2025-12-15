# frozen_string_literal: true

class RemoveVaccineNivsName < ActiveRecord::Migration[8.1]
  def change
    remove_column :vaccines, :nivs_name, :text
  end
end
