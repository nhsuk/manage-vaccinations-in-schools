# frozen_string_literal: true

class Reports::AutomatedCareplusExporter
  def self.call(team:, programme:, academic_year:, start_date:, end_date:)
    Reports::CareplusExporter.call(
      team:,
      programme:,
      academic_year:,
      start_date:,
      end_date:,
      export_type: :automated
    )
  end

  private_class_method :new
end
