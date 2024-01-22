class RemoveSessionName < ActiveRecord::Migration[7.1]
  def change
    remove_column :sessions, :name, :text
  end
end
