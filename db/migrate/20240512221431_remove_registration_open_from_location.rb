class RemoveRegistrationOpenFromLocation < ActiveRecord::Migration[7.1]
  def change
    remove_column :locations, :registration_open, :boolean
  end
end
