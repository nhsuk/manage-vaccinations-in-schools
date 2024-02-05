class AddTeamIdToSessions < ActiveRecord::Migration[7.1]
  def change
    add_reference :sessions, :team, foreign_key: true
  end
end
