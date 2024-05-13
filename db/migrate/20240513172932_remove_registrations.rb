class RemoveRegistrations < ActiveRecord::Migration[7.1]
  def up
    drop_table :registrations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
