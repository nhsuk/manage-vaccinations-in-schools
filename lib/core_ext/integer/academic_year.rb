# frozen_string_literal: true

class Integer
  def to_academic_year_date_range
    start_date = Date.new(self, 9, 1)
    end_date = Date.new(self + 1, 8, 31)
    start_date..end_date
  end
end
