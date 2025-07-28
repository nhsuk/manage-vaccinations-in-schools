# frozen_string_literal: true

class AddWorkgroupToTeams < ActiveRecord::Migration[8.0]
  def change
    change_table :teams, bulk: true do |t|
      t.string :workgroup
      t.index :workgroup, unique: true
    end

    # We assign a random string to the workgroups to satisfy the NOT NULL
    # constraint, but these will be changed later.

    reversible do |dir|
      dir.up do
        Team.find_each do |team|
          team.update_column(:workgroup, SecureRandom.uuid)
        end
      end
    end

    change_column_null :teams, :workgroup, false
  end
end
