# frozen_string_literal: true

class LocationPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def show? = team.has_point_of_care_access?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:team_locations).where(
        team_locations: {
          academic_year: AcademicYear.pending,
          team:
        }
      )
    end
  end
end
