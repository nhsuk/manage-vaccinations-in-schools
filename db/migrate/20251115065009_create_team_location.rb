# frozen_string_literal: true

class CreateTeamLocation < ActiveRecord::Migration[8.1]
  def change
    create_table :team_locations do |t|
      t.references :team, foreign_key: true, null: false
      t.references :location, foreign_key: true, null: false
      t.references :subteam, foreign_key: true
      t.integer :academic_year, null: false
      t.index %i[team_id academic_year location_id], unique: true
      t.timestamps
    end
  end
end
