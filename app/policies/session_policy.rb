# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.teams)
    end
  end
end
