# frozen_string_literal: true

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
end
