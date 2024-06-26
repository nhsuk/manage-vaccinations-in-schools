# frozen_string_literal: true

class AddPrivacyPolicyUrlToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :privacy_policy_url, :string
  end
end
