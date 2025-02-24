# frozen_string_literal: true

class RemoveRecipientFromNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    remove_column :notify_log_entries, :recipient, :string, null: false
  end
end
