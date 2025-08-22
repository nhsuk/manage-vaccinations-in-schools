# frozen_string_literal: true

class TriagePolicy < ApplicationPolicy
  def create?
    user.can_supply_using_pgd?
  end

  def update?
    user.can_supply_using_pgd?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
