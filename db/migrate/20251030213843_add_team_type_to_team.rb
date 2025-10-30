class AddTeamTypeToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :team_type, :integer, default: 0

    reversible do |direction|
      direction.up do
        Team.find_each { |team| team.update_column(:team_type, 0) }
      end
    end

    change_column_null :teams, :team_type, false
  end
end
