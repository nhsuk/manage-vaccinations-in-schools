# frozen_string_literal: true

class PatientSessionPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:session).where(session: { team_id: @user.teams.ids })
    end
  end
end
