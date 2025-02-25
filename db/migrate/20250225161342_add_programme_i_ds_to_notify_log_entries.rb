# frozen_string_literal: true

class AddProgrammeIDsToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :notify_log_entries,
               :programme_ids,
               :integer,
               array: true,
               default: [],
               null: false
  end
end
