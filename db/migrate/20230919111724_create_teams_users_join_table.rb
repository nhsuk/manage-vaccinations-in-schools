# frozen_string_literal: true

class CreateTeamsUsersJoinTable < ActiveRecord::Migration[7.0]
  def change
    create_join_table :teams, :users do |t|
      t.index %i[team_id user_id]
      t.index %i[user_id team_id]
    end
  end
end
