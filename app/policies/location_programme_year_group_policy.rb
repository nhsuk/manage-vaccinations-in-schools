# frozen_string_literal: true

class LocationProgrammeYearGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(location: :subteam).where(
        subteams: {
          team: user.selected_team
        }
      )
    end
  end
end
