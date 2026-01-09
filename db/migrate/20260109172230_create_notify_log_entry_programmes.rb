# frozen_string_literal: true

class CreateNotifyLogEntryProgrammes < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :notify_log_entry_programmes,
                 primary_key: %i[notify_log_entry_id programme_type] do |t|
      t.references :notify_log_entry, null: false, foreign_key: true
      t.enum :programme_type, enum_type: :programme_type, null: false
      t.enum :disease_types, enum_type: :disease_type, array: true, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
