# frozen_string_literal: true

class BackfillPurposeForNotifyLogEntries < ActiveRecord::Migration[8.1]
  def up
    migration = self.class.name
    started_at = Time.zone.now

    scope = NotifyLogEntry.where(purpose: nil)
    distinct_pairs = scope.distinct.pluck(:template_id, :type)

    records_updated = 0

    Rails.logger.info(
      event: "data_migration_start",
      migration:,
      total_records: scope.count,
      distinct_pairs_count: distinct_pairs.size
    )

    distinct_pairs.each_with_index do |template_id, type, index|
      template_name = NotifyTemplate.find_by_id(template_id, channel: type.to_sym)&.name
      next unless template_name

      purpose = NotifyLogEntry.purpose_for_template_name(template_name)
      next unless purpose

      updated_count = NotifyLogEntry
        .where(purpose: nil, template_id:, type:)
        .update_all(purpose: NotifyLogEntry.purposes.fetch(purpose))

      records_updated += updated_count

      Rails.logger.info(
        event: "data_migration_pair",
        migration:,
        pair_index: index + 1,
        total_pairs: distinct_pairs.size,
        template_id:,
        type:,
        purpose:,
        updated_count:
      )
    end

    duration_minutes = ((Time.zone.now - started_at) / 60.0).round

    Rails.logger.info(
      event: "data_migration_finish",
      migration:,
      duration_minutes:,
      records_updated:
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
