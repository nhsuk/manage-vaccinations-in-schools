# frozen_string_literal: true

class AddSettingsToTeams < ActiveRecord::Migration[7.2]
  def change
    change_table :teams, bulk: true do |t|
      t.integer :days_between_first_session_and_consent_requests,
                default: 21,
                null: false

      t.integer :days_between_consent_requests_and_first_reminders,
                default: 7,
                null: false
      t.integer :days_between_subsequent_consent_reminders,
                default: 7,
                null: false
      t.integer :maximum_number_of_consent_reminders, default: 4, null: false

      t.boolean :send_updates_by_text, default: false, null: false
    end
  end
end
