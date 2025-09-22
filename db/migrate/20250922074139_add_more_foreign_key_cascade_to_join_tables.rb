# frozen_string_literal: true

class AddMoreForeignKeyCascadeToJoinTables < ActiveRecord::Migration[8.0]
  FOREIGN_KEYS = [
    %w[consent_notification_programmes consent_notifications],
    %w[consent_notification_programmes programmes],
    %w[session_programmes sessions],
    %w[session_programmes programmes],
    %w[team_programmes teams],
    %w[team_programmes programmes]
  ].freeze

  def change
    FOREIGN_KEYS.each do |foreign_key|
      remove_foreign_key foreign_key.first, foreign_key.last
      add_foreign_key foreign_key.first,
                      foreign_key.last,
                      on_delete: :cascade,
                      validate: false
    end
  end
end
