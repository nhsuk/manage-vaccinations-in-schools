# frozen_string_literal: true

class RemoveConsentReminderSentAtFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :consent_reminder_sent_at, :datetime
  end
end
