# frozen_string_literal: true

class BackfillPatientIdOnNotifyLogEntries < ActiveRecord::Migration[8.1]
  def up
    migration = self.class.name
    started_at = Time.zone.now

    scope = NotifyLogEntry.where(patient_id: nil).where.not(consent_form_id: nil)

    Rails.logger.info(event: "data_migration_start", migration:, total_records: scope.count)

    records_updated =
      scope
        .joins(
          "INNER JOIN consents ON consents.consent_form_id = notify_log_entries.consent_form_id"
        )
        .update_all("patient_id = consents.patient_id")

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
