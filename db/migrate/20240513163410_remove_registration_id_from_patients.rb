class RemoveRegistrationIdFromPatients < ActiveRecord::Migration[7.1]
  def change
    remove_column :patients, :registration_id, :string
  end
end
