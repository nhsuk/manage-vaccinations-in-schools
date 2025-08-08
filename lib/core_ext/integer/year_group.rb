# frozen_string_literal: true

class Integer
  AGE_CHILDREN_START_SCHOOL = 5

  def to_year_group(academic_year: nil)
    (academic_year || Date.current.academic_year) - self -
      AGE_CHILDREN_START_SCHOOL
  end

  alias_method :to_birth_academic_year, :to_year_group
end
