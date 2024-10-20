# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.unarchived.where(team: user.teams)
    end
  end
end
