# frozen_string_literal: true

class GenerateVaccinationReportJob < ApplicationJob
  queue_as :default

  def perform(vaccination_report_export_id)
    export = VaccinationReportExport.find(vaccination_report_export_id)

    return if export.ready? || export.failed? || export.expired?

    csv_string = generate_csv(export)
    export.file.attach(
      io: StringIO.new(csv_string),
      filename: export.csv_filename,
      content_type: "text/csv"
    )
    export.ready!
    export.set_expired_at!
  rescue StandardError => e
    Rails.logger.error(
      "GenerateVaccinationReportJob failed for export #{vaccination_report_export_id}: #{e.class} - #{e.message}"
    )
    export&.failed!
    raise
  end

  private

  def generate_csv(export)
    exporter_class = {
      "careplus" => Reports::CareplusExporter,
      "mavis" => Reports::ProgrammeVaccinationsExporter,
      "systm_one" => Reports::SystmOneExporter
    }.fetch(export.file_format)

    exporter_class.call(
      team: export.team,
      programme: export.programme,
      academic_year: export.academic_year,
      start_date: export.date_from,
      end_date: export.date_to
    )
  end
end
