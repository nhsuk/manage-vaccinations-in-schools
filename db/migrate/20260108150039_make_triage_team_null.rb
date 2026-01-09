# frozen_string_literal: true

class MakeTriageTeamNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :triages, :team_id, true
  end
end
