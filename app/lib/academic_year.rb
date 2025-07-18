# frozen_string_literal: true

module AcademicYear
  class << self
    def all = (first..last).to_a

    def current = Date.current.academic_year

    # 2024 is the year we ran Mavis. We support earlier years only in the case
    # where the service is running in an environment prior to 2024 (only used
    # when changing the date in tests).
    def first = [2024, current].min

    def last = preparation? ? current + 1 : current

    def preparation? = Date.current >= preparation_start_date

    private

    def preparation_start_date
      start_date = (current + 1).to_academic_year_date_range.first
      days_of_preparation =
        Settings.number_of_preparation_days_before_academic_year_starts.to_i
      start_date - days_of_preparation.days
    end
  end
end
