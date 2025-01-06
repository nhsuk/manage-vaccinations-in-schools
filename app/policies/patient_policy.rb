# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      return scope.none if organisation.nil?

      scope.in_organisation(organisation)
    end
  end
end
