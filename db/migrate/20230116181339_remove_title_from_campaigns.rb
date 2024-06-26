# frozen_string_literal: true

class RemoveTitleFromCampaigns < ActiveRecord::Migration[7.0]
  def change
    remove_column :campaigns, :title, :text
  end
end
