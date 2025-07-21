# frozen_string_literal: true

class Date
  def academic_year
    if month >= 9
      year
    else
      year - 1
    end
  end
  def self.academic_year_range(academic_year)
    Date.new(academic_year, 9, 1).beginning_of_day..Date.new(
      academic_year + 1,
      8,
      31
    ).end_of_day
  end
end
