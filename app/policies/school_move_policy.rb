# frozen_string_literal: true

class SchoolMovePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      scope
        .where(school: team.schools)
        .or(scope.where(team:))
        .or(scope.where(patient: team.patients))
    end
  end
end
