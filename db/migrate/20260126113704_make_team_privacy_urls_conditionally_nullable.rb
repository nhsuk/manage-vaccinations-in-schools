# frozen_string_literal: true

class MakeTeamPrivacyUrlsConditionallyNullable < ActiveRecord::Migration[8.0]
  def change
    change_table :teams, bulk: true do |t|
      t.change_null :privacy_notice_url, true
      t.change_null :privacy_policy_url, true
    end
  end
end
