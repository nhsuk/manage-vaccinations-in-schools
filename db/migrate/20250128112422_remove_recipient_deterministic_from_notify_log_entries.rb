# frozen_string_literal: true

class RemoveRecipientDeterministicFromNotifyLogEntries < ActiveRecord::Migration[
  8.0
]
  def change
    remove_column :notify_log_entries, :recipient_deterministic, :string
  end
end
