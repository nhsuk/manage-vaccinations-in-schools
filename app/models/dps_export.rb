# frozen_string_literal: true

require "csv"

class DPSExport
  def initialize(vaccinations)
    @vaccinations = vaccinations
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << DPSExportRow::FIELDS.map(&:upcase)

      @vaccinations.each { csv << DPSExportRow.new(_1).to_a }
    end
  end

  def export_csv
    csv = to_csv
    @vaccinations.update_all(exported_to_dps_at: Time.zone.now)
    csv
  end
end
