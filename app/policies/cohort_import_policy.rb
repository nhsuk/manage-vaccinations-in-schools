# frozen_string_literal: true

class CohortImportPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(team: @user.teams)
    end
  end
end
