# frozen_string_literal: true

class TriagePolicy < ApplicationPolicy
  def create?
    user.is_nurse? || user.is_prescriber?
  end

  def update?
    user.is_nurse? || user.is_prescriber?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
