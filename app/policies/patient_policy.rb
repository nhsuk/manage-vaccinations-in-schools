# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .left_outer_joins(:cohort, :school)
        .where(cohort: { organisation: user.selected_organisation })
        .or(Patient.where(school: { organisation: user.selected_organisation }))
    end
  end
end
