# frozen_string_literal: true

class AddConsentTimestampsToSession < ActiveRecord::Migration[7.1]
  def change
    change_table :sessions, bulk: true do |t|
      t.datetime :send_consent_at
      t.datetime :send_reminders_at
      t.datetime :close_consent_at
    end
  end
end
