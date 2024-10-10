# frozen_string_literal: true

class ChangeReminderDefaults < ActiveRecord::Migration[7.2]
  def change
    change_table :teams, bulk: true do |t|
      t.remove :maximum_number_of_consent_reminders,
               type: :integer,
               default: 4,
               null: false
      t.remove :days_between_consent_reminders,
               type: :integer,
               default: 7,
               null: false
      t.rename :days_between_first_session_and_consent_requests,
               :days_before_consent_requests
      t.rename :days_before_first_consent_reminder,
               :days_before_consent_reminders
      t.remove :send_updates_by_text,
               type: :boolean,
               default: false,
               null: false
    end

    change_table :sessions, bulk: true do |t|
      t.remove :maximum_number_of_consent_reminders,
               type: :integer,
               default: 4,
               null: false
      t.remove :days_between_consent_reminders,
               type: :integer,
               default: 7,
               null: false
      t.rename :days_before_first_consent_reminder,
               :days_before_consent_reminders
    end
  end
end
