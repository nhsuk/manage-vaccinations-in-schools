# frozen_string_literal: true

class AddTypeToConsentNotifications < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/BulkChangeTable
  def up
    add_column :consent_notifications, :type, :integer

    ConsentNotification.find_each do |consent_notification|
      consent_notification.update!(type: consent_notification.reminder ? 1 : 0)
    end

    change_column_null :consent_notifications, :type, false

    remove_column :consent_notifications, :reminder
  end

  def down
    add_column :consent_notifications, :reminder, :boolean

    ConsentNotification.find_each do |consent_notification|
      consent_notification.update!(reminder: consent_notification.type == 1)
    end

    change_column_null :consent_notifications, :type, false

    remove_column :consent_notifications, :type
  end
  # rubocop:enable Rails/BulkChangeTable
end
