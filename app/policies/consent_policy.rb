# frozen_string_literal: true

class ConsentPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.teams)
    end
  end
end
