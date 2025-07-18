# frozen_string_literal: true

module AcademicYearsHelper
  def format_academic_year(academic_year)
    "#{academic_year} to #{academic_year + 1}"
  end
end
