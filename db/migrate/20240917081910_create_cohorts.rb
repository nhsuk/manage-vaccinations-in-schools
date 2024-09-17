# frozen_string_literal: true

class CreateCohorts < ActiveRecord::Migration[7.2]
  def change
    create_table :cohorts do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :academic_year, null: false
      t.integer :year_group, null: false
      t.index %i[team_id academic_year year_group], unique: true
      t.timestamps
    end
  end
end
