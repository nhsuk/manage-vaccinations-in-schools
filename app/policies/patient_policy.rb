# frozen_string_literal: true

class PatientPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope
        .left_outer_joins(:cohort, :school)
        .where(cohort: { team: @user.teams })
        .or(Patient.where(school: { team: @user.teams }))
    end
  end
end
