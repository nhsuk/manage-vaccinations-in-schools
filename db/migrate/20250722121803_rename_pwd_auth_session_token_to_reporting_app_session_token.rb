class RenamePwdAuthSessionTokenToReportingAppSessionToken < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :pwd_auth_session_token, :reporting_app_session_token
  end
end
