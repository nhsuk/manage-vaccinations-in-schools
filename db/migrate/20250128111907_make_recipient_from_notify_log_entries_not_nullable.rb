# frozen_string_literal: true

class MakeRecipientFromNotifyLogEntriesNotNullable < ActiveRecord::Migration[
  8.0
]
  def change
    change_column_null :notify_log_entries, :recipient, false
  end
end
