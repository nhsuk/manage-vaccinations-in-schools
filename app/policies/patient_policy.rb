# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .left_outer_joins(:cohort, :school)
        .where(cohort: { team: user.teams })
        .or(Patient.where(school: { team: user.teams }))
    end
  end
end
