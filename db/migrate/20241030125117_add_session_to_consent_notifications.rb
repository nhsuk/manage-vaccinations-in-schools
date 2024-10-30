# frozen_string_literal: true

class AddSessionToConsentNotifications < ActiveRecord::Migration[7.2]
  def change
    add_reference :consent_notifications, :session, foreign_key: true

    reversible do |dir|
      # We can't get an specific session for historical records, but new
      # notifications going forward will be correct.
      dir.up do
        if Session.any?
          ConsentNotification.update_all(session_id: Session.first.id)
        end
      end
    end

    change_column_null :consent_notifications, :session_id, false
  end
end
