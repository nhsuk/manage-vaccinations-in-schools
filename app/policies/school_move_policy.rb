# frozen_string_literal: true

class SchoolMovePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      return scope.none if organisation.nil?

      scope
        .where(school: organisation.schools)
        .or(scope.where(organisation:))
        .or(scope.where(patient: Patient.in_organisation(organisation)))
    end
  end
end
