# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.selected_team.programmes.ids)
    end
  end
end
