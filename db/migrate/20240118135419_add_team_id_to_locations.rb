# frozen_string_literal: true

class AddTeamIdToLocations < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :team_id, :integer, null: false # rubocop:disable Rails/NotNullColumn
    add_foreign_key :locations, :teams, column: :team_id
  end
end
