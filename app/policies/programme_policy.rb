# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.selected_organisation.programmes.ids)
    end
  end
end
