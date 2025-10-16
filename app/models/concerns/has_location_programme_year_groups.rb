# frozen_string_literal: true

module HasLocationProgrammeYearGroups
  extend ActiveSupport::Concern

  def year_groups
    @year_groups ||= location_programme_year_groups.pluck_year_groups
  end

  def programme_year_groups(academic_year: nil)
    academic_year ||= self.academic_year
    @programme_year_groups ||= {}
    @programme_year_groups[academic_year] ||= ProgrammeYearGroups.new(
      location_programme_year_groups,
      academic_year:
    )
  end
end
