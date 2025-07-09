class AddUserPwdAuthSessionToken < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :pwd_auth_session_token, :string, null: true
  end
end
