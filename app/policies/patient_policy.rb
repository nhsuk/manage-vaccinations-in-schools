# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .left_outer_joins(:cohort, :school)
        .where(cohort: { team: user.selected_team })
        .or(Patient.where(school: { team: user.selected_team }))
    end
  end
end
