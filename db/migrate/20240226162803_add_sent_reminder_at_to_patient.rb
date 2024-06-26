# frozen_string_literal: true

class AddSentReminderAtToPatient < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :sent_reminder_at, :datetime
  end
end
