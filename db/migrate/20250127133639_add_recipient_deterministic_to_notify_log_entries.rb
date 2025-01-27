# frozen_string_literal: true

class AddRecipientDeterministicToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :notify_log_entries, :recipient_deterministic, :string
  end
end
