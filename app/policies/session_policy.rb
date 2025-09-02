# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def import? = show?

  def make_in_progress? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .where(team: user.selected_team)
        .then do |scope|
          user.is_healthcare_assistant? ? scope.supports_delegation : scope
        end
    end
  end
end
