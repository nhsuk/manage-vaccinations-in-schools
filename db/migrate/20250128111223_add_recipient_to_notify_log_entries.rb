# frozen_string_literal: true

class AddRecipientToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :notify_log_entries, :recipient, :string
  end
end
