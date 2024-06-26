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

    def age
      date_of_birth_value = __send__(self.class.date_of_birth_field_for_age)
      now = Time.zone.now.to_date

      month_is_greater = now.month > date_of_birth_value.month
      month_matches = now.month == date_of_birth_value.month
      day_is_greater_or_equal = now.day >= date_of_birth_value.day

      now.year - date_of_birth_value.year -
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
