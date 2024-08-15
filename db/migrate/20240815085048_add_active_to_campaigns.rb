# frozen_string_literal: true

class AddActiveToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :active, :boolean, default: false, null: false
  end
end
