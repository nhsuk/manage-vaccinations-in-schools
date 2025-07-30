# frozen_string_literal: true

class Location::ProgrammeYearGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(location: :subteam).where(
        subteams: {
          organisation: user.selected_organisation
        }
      )
    end
  end
end
