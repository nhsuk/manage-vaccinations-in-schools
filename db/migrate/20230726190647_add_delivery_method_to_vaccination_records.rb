# frozen_string_literal: true

class AddDeliveryMethodToVaccinationRecords < ActiveRecord::Migration[7.0]
  def change
    change_table :vaccination_records, bulk: true do |t|
      t.integer :delivery_method
    end
  end
end
