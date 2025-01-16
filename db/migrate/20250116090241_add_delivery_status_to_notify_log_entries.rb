# frozen_string_literal: true

class AddDeliveryStatusToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :notify_log_entries,
               :delivery_status,
               :integer,
               null: false,
               default: 0
  end
end
