# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.in_organisation(user.selected_organisation)
    end
  end
end
