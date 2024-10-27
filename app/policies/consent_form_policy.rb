# frozen_string_literal: true

class ConsentFormPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
