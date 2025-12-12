# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.selected_team.id)
    end
  end
end
