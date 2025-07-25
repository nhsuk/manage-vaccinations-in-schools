# frozen_string_literal: true

class RenameTeamToSubteam < ActiveRecord::Migration[8.0]
  def change
    rename_table :teams, :subteams
    rename_column :locations, :team_id, :subteam_id
  end
end
