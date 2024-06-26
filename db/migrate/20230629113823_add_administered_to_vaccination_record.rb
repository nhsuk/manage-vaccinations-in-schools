# frozen_string_literal: true

class AddAdministeredToVaccinationRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :vaccination_records, :administered, :boolean
  end
end
