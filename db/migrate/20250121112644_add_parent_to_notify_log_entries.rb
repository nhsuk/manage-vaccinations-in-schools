# frozen_string_literal: true

class AddParentToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :notify_log_entries,
                  :parent,
                  foreign_key: {
                    on_delete: :nullify
                  }
  end
end
