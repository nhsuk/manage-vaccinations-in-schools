class ChangeGpFieldTypeInPatients < ActiveRecord::Migration[7.0]
  def up
    change_column :patients, :gp, :string, null: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
