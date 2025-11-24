# frozen_string_literal: true

class ProgrammeYearGroups
  def initialize(location_programme_year_groups, academic_year:)
    @location_programme_year_groups = location_programme_year_groups
    @academic_year = academic_year

    @year_groups = {}
    @birth_academic_years = {}
  end

  def [](programme)
    @year_groups[programme.type] ||= year_groups_for_programme(programme)
  end

  def birth_academic_years(programme)
    @birth_academic_years[programme.type] ||= self[programme].map do
      it.to_birth_academic_year(academic_year:)
    end
  end

  def is_catch_up?(year_group, programme:)
    return nil if programme.seasonal?
    return true if programme.catch_up_only?
    return nil if self[programme].empty?
    self[programme].first != year_group
  end

  private

  attr_reader :location_programme_year_groups, :academic_year

  def year_groups_for_programme(programme)
    if location_programme_year_groups.is_a?(Array) ||
         location_programme_year_groups.loaded?
      location_programme_year_groups
        .select { it.programme_type == programme.type }
        .select { it.academic_year == academic_year }
        .map(&:year_group)
        .sort
        .uniq
    else
      location_programme_year_groups
        .joins(:location_year_group)
        .where_programme(programme)
        .where(location_year_group: { academic_year: })
        .pluck_year_groups
    end
  end
end
