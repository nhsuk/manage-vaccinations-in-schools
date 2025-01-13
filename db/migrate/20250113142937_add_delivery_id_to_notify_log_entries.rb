# frozen_string_literal: true

class AddDeliveryIdToNotifyLogEntries < ActiveRecord::Migration[8.0]
  def up
    change_table :notify_log_entries, bulk: true do |t|
      t.uuid :delivery_id
      t.change :template_id, :uuid, null: false, using: "template_id::uuid"
    end
  end

  def down
    change_table :notify_log_entries, bulk: true do |t|
      t.change :template_id, :string, null: false
      t.remove :delivery_id
    end
  end
end
