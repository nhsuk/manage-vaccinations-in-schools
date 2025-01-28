# frozen_string_literal: true

class MakeNotifyLogEntryRecipientNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :notify_log_entries, :recipient, true
  end
end
