# frozen_string_literal: true

class RemoveProgrammeTypesFromNotifyLogEntries < ActiveRecord::Migration[8.1]
  def change
    remove_column :notify_log_entries,
                  :programme_types,
                  :enum,
                  default: [],
                  array: true,
                  null: false
  end
end
