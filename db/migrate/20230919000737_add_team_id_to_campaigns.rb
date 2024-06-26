# frozen_string_literal: true

class AddTeamIdToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :team_id, :integer, null: true
    add_foreign_key :campaigns, :teams, column: :team_id
  end
end
