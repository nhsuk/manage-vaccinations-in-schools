# frozen_string_literal: true

class VaccinePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      scope.where(programme_type: team.programme_types)
    end
  end
end
