# frozen_string_literal: true

class AddStartAndEndYearToCampaigns < ActiveRecord::Migration[7.1]
  def change
    change_table :campaigns, bulk: true do |t|
      t.date :start_date
      t.date :end_date
    end
  end
end
