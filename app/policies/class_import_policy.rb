# frozen_string_literal: true

class ClassImportPolicy < ApplicationPolicy
  def approve? = edit?

  def re_review? = edit?

  def cancel? = edit?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(team: user.selected_team)
    end
  end
end
