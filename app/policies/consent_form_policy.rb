# frozen_string_literal: true

class ConsentFormPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:session).where(session: { team: @user.teams })
    end
  end
end
