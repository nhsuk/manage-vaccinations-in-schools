# frozen_string_literal: true

class SessionPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:campaign).where(campaign: { team_id: @user.teams.ids })
    end
  end

  class DraftScope
    # When dealing with draft sessions we need to account for the possibility
    # that the campaign or location fields aren't set yet, e.g. during creation.
    # Users can see draft sessions with no location or campaign.

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.and(
        Session.where(campaign: nil).or(
          Session.where(campaign: @user.team.campaigns)
        )
      ).draft
    end
  end
end
