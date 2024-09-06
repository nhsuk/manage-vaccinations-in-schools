# frozen_string_literal: true

class VaccinePolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:programmes).where(programmes: { team_id: @user.teams.ids })
    end
  end
end
