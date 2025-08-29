# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    next unless example.metadata[:within_academic_year]

    within_academic_year = example.metadata[:within_academic_year]

    from_start =
      (within_academic_year.is_a?(Hash) ? within_academic_year[:from_start] : 0)
    test_date = Date.current - from_start

    if test_date.academic_year != AcademicYear.pending
      travel_to(Date.new(AcademicYear.pending, 9, 1) + from_start)
    end
  end
end
