# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  def edit_archive? = edit?

  def update_archive? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
