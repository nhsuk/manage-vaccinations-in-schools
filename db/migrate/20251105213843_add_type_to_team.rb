# frozen_string_literal: true

class AddTypeToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :type, :integer

    reversible do |direction|
      direction.up { Team.find_each { |team| team.update_column(:type, 0) } }
    end

    change_column_null :teams, :type, false
  end
end
