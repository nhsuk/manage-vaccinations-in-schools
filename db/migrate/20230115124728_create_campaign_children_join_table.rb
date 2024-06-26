# frozen_string_literal: true

class CreateCampaignChildrenJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :campaigns, :children do |t|
      t.index %i[campaign_id child_id]
      t.index %i[child_id campaign_id]

      t.timestamps
    end
  end
end
