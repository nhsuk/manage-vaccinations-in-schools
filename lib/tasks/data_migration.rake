# frozen_string_literal: true

namespace :data_migration do
  desc "Backfill NotifyLogEntry::Programme records"
  task backfill_notify_log_entry_programmes: :environment do
    DataMigration::BackfillNotifyLogEntryProgrammes.call
  end

  desc "Update HPV health questions."
  task update_hpv_health_questions: :environment do
    ActiveRecord::Base.transaction do
      Programme.hpv.vaccines.find_each do |vaccine|
        vaccine.health_questions.in_order.each(&:destroy!)
        Rake::Task["vaccines:seed"].execute(type: "hpv")
      end
    end
  end
end
