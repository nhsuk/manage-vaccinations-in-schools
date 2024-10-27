# frozen_string_literal: true

class AddSenderToNotifyLogEntries < ActiveRecord::Migration[7.2]
  def change
    add_reference :notify_log_entries,
                  :sent_by_user,
                  foreign_key: {
                    to_table: :users
                  }

    add_reference :consent_notifications,
                  :sent_by_user,
                  foreign_key: {
                    to_table: :users
                  }

    add_reference :session_notifications,
                  :sent_by_user,
                  foreign_key: {
                    to_table: :users
                  }
  end
end
