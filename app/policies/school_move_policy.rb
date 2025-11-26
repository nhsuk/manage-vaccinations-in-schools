# frozen_string_literal: true

class SchoolMovePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      patient_in_team =
        team
          .patients
          .select("1")
          .where("patients.id = school_moves.patient_id")
          .arel
          .exists

      scope
        .where(patient_in_team)
        .where(school: nil)
        .or(scope.where(school: team.schools))
        .or(scope.where(team:))
    end
  end
end
