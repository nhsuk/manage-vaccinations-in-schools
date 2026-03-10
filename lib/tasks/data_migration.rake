# frozen_string_literal: true

namespace :data_migration do
  desc "Backfill purpose column for NotifyLogEntry records"
  task backfill_notify_log_entries: :environment do
    DataMigration::BackfillNotifyLogEntries.call
  end
end
