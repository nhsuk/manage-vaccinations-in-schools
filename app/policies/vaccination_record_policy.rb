# frozen_string_literal: true

class VaccinationRecordPolicy
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
