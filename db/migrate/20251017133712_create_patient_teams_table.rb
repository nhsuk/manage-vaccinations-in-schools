# frozen_string_literal: true

class CreatePatientTeamsTable < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :patient_teams, primary_key: %i[team_id patient_id] do |t|
      t.references :patient, null: false, foreign_key: { on_delete: :cascade }
      t.references :team, null: false, foreign_key: { on_delete: :cascade }
      t.integer :sources, null: false, array: true

      t.index %i[patient_id team_id]
      t.index %i[sources], using: :gin
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
