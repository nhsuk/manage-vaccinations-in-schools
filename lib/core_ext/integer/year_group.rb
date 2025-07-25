# frozen_string_literal: true

class Integer
  def to_year_group(academic_year:)
    # Children normally start school the September after their 4th birthday.
    # https://www.gov.uk/schools-admissions/school-starting-age

    (academic_year || Date.current.academic_year) - self - 5
  end

  alias_method :to_birth_academic_year, :to_year_group
end
