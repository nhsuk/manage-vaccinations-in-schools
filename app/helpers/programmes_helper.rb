# frozen_string_literal: true

module ProgrammesHelper
  def programme_academic_year(value)
    academic_year = value.is_a?(Programme) ? value.academic_year : value

    year_1 = academic_year.to_s
    year_2 = (academic_year + 1).to_s
    "#{year_1}/#{year_2[2..3]}"
  end
end
