# frozen_string_literal: true

class CampaignPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(team: @user.team)
    end
  end
end
