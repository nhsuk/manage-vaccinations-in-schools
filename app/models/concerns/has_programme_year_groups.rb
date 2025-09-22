# frozen_string_literal: true

module HasProgrammeYearGroups
  extend ActiveSupport::Concern

  def programme_year_groups(academic_year:)
    @programme_year_groups ||= {}
    @programme_year_groups[academic_year] ||= ProgrammeYearGroups.new(
      location_programme_year_groups.where(academic_year:)
    )
  end
end
