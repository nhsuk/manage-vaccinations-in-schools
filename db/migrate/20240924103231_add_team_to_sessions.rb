# frozen_string_literal: true

class AddTeamToSessions < ActiveRecord::Migration[7.2]
  def up
    add_reference :sessions, :team, foreign_key: true

    Session.all.find_each do |session|
      session.update!(team_id: (session.programme&.team || Team.first).id)
    end

    change_column_null :sessions, :team_id, false
  end

  def down
    remove_reference :sessions, :team
  end
end
