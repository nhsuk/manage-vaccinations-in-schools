# frozen_string_literal: true

class MakeSessionCampaignOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :sessions, :campaign_id, true
  end
end
