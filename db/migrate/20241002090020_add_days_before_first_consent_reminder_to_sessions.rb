# frozen_string_literal: true

class AddDaysBeforeFirstConsentReminderToSessions < ActiveRecord::Migration[7.2]
  def change
    change_table :sessions, bulk: true do |t|
      t.integer :days_before_first_consent_reminder
      t.remove :send_consent_reminders_at, type: :datetime
    end

    rename_column :teams,
                  :days_between_consent_requests_and_first_reminders,
                  :days_before_first_consent_reminder
  end
end
