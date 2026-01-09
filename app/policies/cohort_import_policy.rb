# frozen_string_literal: true

class CohortImportPolicy < ApplicationPolicy
  def approve? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
