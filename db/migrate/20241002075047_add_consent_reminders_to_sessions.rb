# frozen_string_literal: true

class AddConsentRemindersToSessions < ActiveRecord::Migration[7.2]
  def change
    change_table :sessions, bulk: true do |t|
      t.integer :days_between_consent_reminders
      t.integer :maximum_number_of_consent_reminders
    end

    rename_column :teams,
                  :days_between_subsequent_consent_reminders,
                  :days_between_consent_reminders
  end
end
