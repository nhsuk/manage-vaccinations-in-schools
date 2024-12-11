# frozen_string_literal: true

class MakeOrganisationPrivacyPolicyUrlNotNull < ActiveRecord::Migration[8.0]
  def up
    Organisation.where(privacy_policy_url: nil).update_all(
      privacy_policy_url: "https://example.com/privacy"
    )
    change_column_null :organisations, :privacy_policy_url, false
  end

  def down
    change_column_null :organisations, :privacy_policy_url, true
  end
end
