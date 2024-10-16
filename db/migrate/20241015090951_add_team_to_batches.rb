# frozen_string_literal: true

class AddTeamToBatches < ActiveRecord::Migration[7.2]
  def up
    add_reference :batches, :team, foreign_key: true
    Batch.update_all(team_id: Team.first.id) if Team.any?
    change_column_null :batches, :team_id, false
    add_index :batches, %i[team_id name expiry vaccine_id], unique: true
  end

  def down
    change_table :batches, bulk: true do |t|
      t.remove_index %i[team_id name expiry vaccine_id]
      t.remove_references :team
    end
  end
end
