# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def update?
    user.is_nurse? || user.is_admin?
  end

  def import? = show?

  def make_in_progress? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
