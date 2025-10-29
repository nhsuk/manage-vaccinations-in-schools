# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team

      return scope.none if team.nil?

      scope.joins(:patient_teams).where(patient_teams: { team_id: team.id })
    end
  end
end
