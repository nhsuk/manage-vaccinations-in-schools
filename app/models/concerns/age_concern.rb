# frozen_string_literal: true

module AgeConcern
  extend ActiveSupport::Concern

  class_methods do
    def date_of_birth_field_for_age(name = nil)
      @date_of_birth_field_for_age = name if name

      @date_of_birth_field_for_age
    end
  end

  included do
    date_of_birth_field_for_age :date_of_birth

    def age_months(now: nil)
      date_of_birth = __send__(self.class.date_of_birth_field_for_age)
      now ||= Time.current

      day_is_greater_or_equal = now.day >= date_of_birth.day

      (now.year - date_of_birth.year) * 12 + now.month - date_of_birth.month -
        (day_is_greater_or_equal ? 0 : 1)
    end

    def age_years(now: nil)
      date_of_birth = __send__(self.class.date_of_birth_field_for_age)
      now ||= Time.current

      month_is_greater = now.month > date_of_birth.month
      month_matches = now.month == date_of_birth.month
      day_is_greater_or_equal = now.day >= date_of_birth.day

      now.year - date_of_birth.year -
        (
          if month_is_greater || (month_matches && day_is_greater_or_equal)
            0
          else
            1
          end
        )
    end
  end
end
