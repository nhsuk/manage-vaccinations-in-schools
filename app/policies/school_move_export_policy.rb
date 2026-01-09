# frozen_string_literal: true

class SchoolMoveExportPolicy < ApplicationPolicy
  def download? = create?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
