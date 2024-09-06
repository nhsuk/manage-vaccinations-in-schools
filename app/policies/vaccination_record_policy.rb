# frozen_string_literal: true

class VaccinationRecordPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:programme).where(programme: { team_id: @user.teams.ids })
    end
  end
end
