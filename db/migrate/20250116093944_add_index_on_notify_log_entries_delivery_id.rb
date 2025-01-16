# frozen_string_literal: true

class AddIndexOnNotifyLogEntriesDeliveryId < ActiveRecord::Migration[8.0]
  def change
    add_index :notify_log_entries, :delivery_id
  end
end
