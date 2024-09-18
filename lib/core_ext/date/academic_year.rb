# frozen_string_literal: true

class Date
  def academic_year
    if month >= 9
      year
    else
      year - 1
    end
  end
end
