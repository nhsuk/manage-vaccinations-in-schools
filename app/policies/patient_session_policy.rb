# frozen_string_literal: true

class PatientSessionPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:campaign).where(campaign: { team_id: @user.teams.ids })
    end
  end
end
