# frozen_string_literal: true

class AddTeamToLocations < ActiveRecord::Migration[7.2]
  def change
    add_reference :locations, :team, foreign_key: true
  end
end
