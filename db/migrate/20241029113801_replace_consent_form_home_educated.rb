# frozen_string_literal: true

class ReplaceConsentFormHomeEducated < ActiveRecord::Migration[7.2]
  def change
    change_table :consent_forms, bulk: true do |t|
      t.remove :home_educated, type: :boolean
      t.integer :education_setting
    end
  end
end
