# frozen_string_literal: true

class Location::ProgrammeYearGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(location: :team).where(
        teams: {
          organisation: user.selected_organisation
        }
      )
    end
  end
end
