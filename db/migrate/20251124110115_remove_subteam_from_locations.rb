# frozen_string_literal: true

class RemoveSubteamFromLocations < ActiveRecord::Migration[8.1]
  def change
    remove_reference :locations, :subteam, foreign_key: true
  end
end
