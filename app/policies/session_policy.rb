# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def import? = show?

  def make_in_progress?
    user.is_nurse? || user.is_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
