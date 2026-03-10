# frozen_string_literal: true

class CleanupVaccinationReportExportsJob < ApplicationJob
  queue_as :default

  def perform
    retention_hours = Settings.vaccination_report_export.retention_hours
    cutoff = retention_hours.hours.ago

    VaccinationReportExport
      .where("created_at < ?", cutoff)
      .find_each do |export|
        export.file.purge if export.file.attached?
        export.expired! unless export.expired?
      end
  end
end
