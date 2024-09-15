# frozen_string_literal: true

class RenameConsentRequestAndReminderColumns < ActiveRecord::Migration[7.2]
  def change
    change_table :patients, bulk: true do |t|
      t.rename :sent_consent_at, :consent_request_sent_at
      t.rename :sent_reminder_at, :consent_reminder_sent_at
    end

    change_table :sessions, bulk: true do |t|
      t.rename :send_consent_at, :send_consent_requests_at
      t.rename :send_reminders_at, :send_consent_reminders_at
    end
  end
end
