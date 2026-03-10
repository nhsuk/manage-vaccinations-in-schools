# frozen_string_literal: true

class BackfillPurposeForNotifyLogEntries < ActiveRecord::Migration[8.1]
  def up
    migration = self.class.name
    started_at = Time.zone.now

    batch_size = 1000
    total_records = NotifyLogEntry.count
    total_batches = (total_records / batch_size.to_f).ceil

    batch_processed = 0
    records_updated = 0

    # Helps us monitor progress in CloudWatch
    Rails.logger.info(event: "data_migration_start", migration:, total_records:, total_batches:)

    NotifyLogEntry.find_in_batches(batch_size:) do |notify_log_entries|
      notify_log_entries.filter_map do |notify_log_entry|
        template_name = NotifyTemplate.find_by_id(
          notify_log_entry.template_id,
          channel: notify_log_entry.type.to_sym
        )&.name

        next unless template_name

        purpose = NotifyLogEntry.purpose_for_template_name(template_name)

        next unless purpose

        notify_log_entry.update_column(
          :purpose,
          NotifyLogEntry.purposes.fetch(purpose)
        )

        records_updated += 1
      end

      batch_processed += 1

      Rails.logger.info(
        event: "data_migration_batch",
        migration:,
        records_updated:,
        batch_size:,
        batch_processed:,
        total_batches:,
        )
    end

    duration_minutes =  ((Time.zone.now - started_at) / 60.0).round

    Rails.logger.info(
      event: "data_migration_finish",
      migration:,
      duration_minutes:,
      total_records:,
      records_updated:,
      )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
