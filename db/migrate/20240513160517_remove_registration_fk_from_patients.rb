class RemoveRegistrationFkFromPatients < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :patients, :registrations
  end
end
