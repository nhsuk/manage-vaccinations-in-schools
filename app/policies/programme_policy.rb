# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.programmes.ids)
    end
  end
end
