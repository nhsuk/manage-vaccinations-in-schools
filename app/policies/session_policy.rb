# frozen_string_literal: true

class SessionPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:programme).where(programme: { team_id: @user.teams.ids })
    end
  end

  class DraftScope
    # When dealing with draft sessions we need to account for the possibility
    # that the programme or location fields aren't set yet, e.g. during creation.
    # Users can see draft sessions with no location or programme.

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.and(
        Session.where(programme: nil).or(
          Session.where(programme: @user.team.programmes)
        )
      ).draft
    end
  end
end
