# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.unarchived.where(team: @user.teams)
    end
  end
end
