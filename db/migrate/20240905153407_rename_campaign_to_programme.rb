# frozen_string_literal: true

class RenameCampaignToProgramme < ActiveRecord::Migration[7.2]
  def change
    rename_table :campaigns, :programmes
    rename_table :campaigns_vaccines, :programmes_vaccines

    rename_column :consents, :campaign_id, :programme_id
    rename_column :dps_exports, :campaign_id, :programme_id
    rename_column :immunisation_imports, :campaign_id, :programme_id
    rename_column :programmes_vaccines, :campaign_id, :programme_id
    rename_column :sessions, :campaign_id, :programme_id
  end
end
