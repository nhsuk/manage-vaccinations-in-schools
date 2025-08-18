# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  def sessions? = index?

  def patients = index?

  def consent_form? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.selected_team.programmes.ids)
    end
  end
end
