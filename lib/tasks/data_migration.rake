# frozen_string_literal: true

desc "Backfill NotifyLogEntry::Programme records"
task backfill_notify_log_entry_programmes: :environment do
  DataMigration::BackfillNotifyLogEntryProgrammes.call
end
