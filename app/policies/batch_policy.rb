# frozen_string_literal: true

class BatchPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(vaccine: { programmes: :team }).where(
        teams: {
          id: @user.teams.ids
        }
      )
    end
  end
end
