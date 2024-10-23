# frozen_string_literal: true

class AddTypeToSessionNotifications < ActiveRecord::Migration[7.2]
  def change
    # rubocop:disable Rails/BulkChangeTable
    add_column :session_notifications, :type, :integer, default: 0, null: false
    change_column_default :session_notifications, :type, from: 0, to: nil
    # rubocop:enable Rails/BulkChangeTable
  end
end
