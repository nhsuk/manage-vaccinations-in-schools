# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  def sessions? = index?

  def patients = index?

  def consent_form? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team

      scope
        .where(type: team.programme_types)
        .then do |scope|
          user.is_healthcare_assistant? ? scope.supports_delegation : scope
        end
    end
  end
end
