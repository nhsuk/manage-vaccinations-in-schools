# frozen_string_literal: true

class ConsentFormPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      scope.where(team:)
    end
  end
end
