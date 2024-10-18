# frozen_string_literal: true

class VaccinePolicy < ApplicationPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:programme).where(programme: @user.programmes)
    end
  end
end
