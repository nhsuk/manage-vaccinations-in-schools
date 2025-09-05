# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  def sessions? = index?

  def patients = index?

  def consent_form? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:team_programmes)
        .where(team_programmes: { team: user.selected_team })
        .then do |scope|
          user.is_healthcare_assistant? ? scope.supports_delegation : scope
        end
    end
  end
end
