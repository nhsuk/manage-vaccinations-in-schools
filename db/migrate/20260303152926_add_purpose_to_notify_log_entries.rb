# frozen_string_literal: true

class AddPurposeToNotifyLogEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :notify_log_entries, :purpose, :integer, null: true
  end
end
