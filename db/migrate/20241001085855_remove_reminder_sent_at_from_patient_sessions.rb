# frozen_string_literal: true

class RemoveReminderSentAtFromPatientSessions < ActiveRecord::Migration[7.2]
  def change
    remove_column :patient_sessions, :reminder_sent_at, :datetime
  end
end
