# frozen_string_literal: true

class RemoveTeamFromProgrammes < ActiveRecord::Migration[7.2]
  def up
    Programme.all.find_each do |programme|
      TeamProgramme.create!(programme:, team_id: programme.team_id)
    end

    remove_reference :programmes, :team, foreign_key: true, null: false

    add_index :programmes, :type, unique: true
  end

  def down
    add_reference :programmes, :team, foreign_key: true

    Programme.all.find_each do |programme|
      programme.update!(
        team_id: TeamProgramme.find_by(programme:)&.team_id || Team.first.id
      )
    end

    change_column_null :programmes, :team_id, false

    remove_index :programmes, :type
    add_index :programmes, %i[type team_id], unique: true
  end
end
