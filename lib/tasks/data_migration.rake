# frozen_string_literal: true

namespace :data_migration do
  desc "Backfill NotifyLogEntry::Programme records"
  task backfill_notify_log_entry_programmes: :environment do
    DataMigration::BackfillNotifyLogEntryProgrammes.call
  end

  desc "Set disease types on all triages."
  task set_triage_disease_types: :environment do
    Triage
      .where(disease_types: nil)
      .find_each do |triage|
        programme = Programme.find(triage.programme_type)

        disease_types =
          if programme.mmr?
            Programme::Variant::DISEASE_TYPES.fetch("mmr")
          else
            programme.disease_types
          end

        triage.update_columns(disease_types:)
      end
  end
end
