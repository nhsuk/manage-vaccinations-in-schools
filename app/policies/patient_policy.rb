# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .left_outer_joins(:cohort, school: :team)
        .where(cohort: { organisation_id: user.selected_organisation.id })
        .or(
          Patient.where(
            team: {
              organisation_id: user.selected_organisation.id
            }
          )
        )
    end
  end
end
