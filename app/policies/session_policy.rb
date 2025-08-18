# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def import? = show?

  def make_in_progress? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
