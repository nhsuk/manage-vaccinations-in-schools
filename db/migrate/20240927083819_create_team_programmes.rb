# frozen_string_literal: true

class CreateTeamProgrammes < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :team_programmes do |t|
      t.references :team, foreign_key: true, null: false
      t.references :programme, foreign_key: true, null: false
      t.index %i[team_id programme_id], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
