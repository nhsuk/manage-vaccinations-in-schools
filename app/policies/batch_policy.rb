class BatchPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(vaccine: { campaigns: :team }).where(
        teams: {
          id: @user.teams.ids
        }
      )
    end
  end
end
