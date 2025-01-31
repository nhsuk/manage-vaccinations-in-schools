# frozen_string_literal: true

module YearGroupConcern
  extend ActiveSupport::Concern

  def year_group
    return nil if birth_academic_year.nil?

    # Children normally start school the September after their 4th birthday.
    # https://www.gov.uk/schools-admissions/school-starting-age

    Date.current.academic_year - (birth_academic_year + 5)
  end

  def year_group_changed?
    birth_academic_year_changed?
  end
end
