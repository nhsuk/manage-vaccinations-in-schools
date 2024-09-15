# frozen_string_literal: true

class AddReminderSentAtToPatientSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :patient_sessions, :reminder_sent_at, :datetime
    remove_column :patients, :session_reminder_sent_at, :datetime
  end
end
