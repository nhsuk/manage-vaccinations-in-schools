# frozen_string_literal: true

module AcademicYear
  class << self
    def all = (first..last).to_a

    def current = Date.current.academic_year

    # 2024 is the year we ran Mavis. We support earlier years only in the case
    # where the service is running in an environment prior to 2024 (only used
    # when changing the date in tests).
    def first = [2024, current].min

    def last = current
  end
end
