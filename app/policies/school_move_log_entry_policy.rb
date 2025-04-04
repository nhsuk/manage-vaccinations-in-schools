# frozen_string_literal: true

class SchoolMoveLogEntryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      return scope.none if organisation.nil?

      scope.where(school: organisation.schools).or(
        scope.where(patient: organisation.patients)
      )
    end
  end
end
