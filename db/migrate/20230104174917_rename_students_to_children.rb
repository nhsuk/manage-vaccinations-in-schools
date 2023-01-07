class RenameStudentsToChildren < ActiveRecord::Migration[7.0]
  def change
    rename_table :students, :children
  end
end
