# frozen_string_literal: true

class AddTypeToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :type, :integer

    reversible { |direction| direction.up { Team.update_all(type: 0) } }

    change_column_null :teams, :type, false
  end
end
