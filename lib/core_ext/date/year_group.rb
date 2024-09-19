# frozen_string_literal: true

class Date
  def year_group
    # Children normally start school the September after their 4th birthday.
    # https://www.gov.uk/schools-admissions/school-starting-age

    Time.zone.today.academic_year - (academic_year + 5)
  end
end
