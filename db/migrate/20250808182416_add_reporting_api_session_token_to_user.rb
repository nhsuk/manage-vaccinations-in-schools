# frozen_string_literal: true

class AddReportingAPISessionTokenToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :reporting_api_session_token, :string, null: true
    add_index :users, :reporting_api_session_token, unique: true
  end
end
