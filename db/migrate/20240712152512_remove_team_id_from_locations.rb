# frozen_string_literal: true

class RemoveTeamIdFromLocations < ActiveRecord::Migration[7.1]
  def change
    remove_reference :locations, :team
  end
end
