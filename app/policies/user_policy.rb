# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(id: @user.id)
    end
  end
end
