class AddObservedSessionAgreedFieldToRegistration < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :observed_session_agreed, :boolean
  end
end
