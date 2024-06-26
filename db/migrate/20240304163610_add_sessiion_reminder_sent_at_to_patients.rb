# frozen_string_literal: true

class AddSessiionReminderSentAtToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :session_reminder_sent_at, :datetime
  end
end
