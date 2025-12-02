# frozen_string_literal: true

class LocationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:team_locations).where(
        team_locations: {
          academic_year: AcademicYear.pending,
          team: user.selected_team
        }
      )
    end
  end
end
