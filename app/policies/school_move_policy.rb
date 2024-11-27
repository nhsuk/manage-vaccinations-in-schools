# frozen_string_literal: true

class SchoolMovePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation

      scope.where(school: organisation.schools).or(
        scope.where(patient: Patient.in_organisation(organisation))
      )
    end
  end
end
