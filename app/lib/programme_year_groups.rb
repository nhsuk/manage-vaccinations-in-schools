# frozen_string_literal: true

class ProgrammeYearGroups
  def initialize(location_programme_year_groups)
    @location_programme_year_groups = location_programme_year_groups

    @year_groups = {}
  end

  def [](programme)
    @year_groups[programme.id] ||= year_groups_for_programme(programme)
  end

  def is_catch_up?(year_group, programme:)
    return nil if programme.seasonal?
    return true if programme.catch_up_only?
    return nil if self[programme].empty?
    self[programme].first != year_group
  end

  private

  attr_reader :location_programme_year_groups

  def year_groups_for_programme(programme)
    if location_programme_year_groups.is_a?(Array) ||
         location_programme_year_groups.loaded?
      location_programme_year_groups
        .select { it.programme_id == programme.id }
        .map(&:year_group)
        .sort
        .uniq
    else
      location_programme_year_groups.where(programme:).pluck_year_groups
    end
  end
end
