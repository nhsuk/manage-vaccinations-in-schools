# frozen_string_literal: true

class MakeCampaignTeamRequired < ActiveRecord::Migration[7.1]
  def up
    Campaign.update_all(team_id: Team.first.id)
    change_column_null :campaigns, :team_id, false
  end

  def down
    change_column_null :campaigns, :team_id, true
  end
end
