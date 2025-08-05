# frozen_string_literal: true

module HasProgrammeYearGroups
  extend ActiveSupport::Concern

  def programme_year_groups
    @programme_year_groups ||=
      ProgrammeYearGroups.new(location_programme_year_groups)
  end
end
