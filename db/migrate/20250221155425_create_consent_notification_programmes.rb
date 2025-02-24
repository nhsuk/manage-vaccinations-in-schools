# frozen_string_literal: true

class CreateConsentNotificationProgrammes < ActiveRecord::Migration[8.0]
  def up
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :consent_notification_programmes do |t|
      t.references :programme, foreign_key: true, null: false
      t.references :consent_notification, foreign_key: true, null: false
      t.index %i[programme_id consent_notification_id], unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    ConsentNotification
      .pluck(:id, :programme_id)
      .each do |consent_notification_id, programme_id|
        ConsentNotificationProgramme.create!(
          consent_notification_id:,
          programme_id:
        )
      end

    remove_reference :consent_notifications, :programme
  end

  def down
    add_reference :consent_notifications, :programme, foreign_key: true

    ConsentNotification
      .includes(:consent_notification_programmes)
      .find_each do |consent_notification|
        consent_notification.update_column(
          :programme_id,
          consent_notification
            .consent_notification_programmes
            .first
            .programme_id
        )
      end

    change_column_null :consent_notifications, :programme_id, false

    drop_table :consent_notification_programmes
  end
end
