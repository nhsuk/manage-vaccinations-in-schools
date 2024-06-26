# frozen_string_literal: true

class ConsentFormPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(session: :campaign).where(
        campaign: {
          team_id: @user.teams.ids
        }
      )
    end
  end
end
