# frozen_string_literal: true

class ConsentFormPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      return scope.none if organisation.nil?

      scope.where(organisation:)
    end
  end
end
