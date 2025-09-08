# frozen_string_literal: true

class SchoolMovePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      patient_subquery =
        Patient
          .joins(patient_locations: :session)
          .select(:id)
          .distinct
          .where(sessions: { team_id: team.id })
          .arel
          .as("patients")
      scope
        .joins(
          SchoolMove
            .arel_table
            .join(patient_subquery, Arel::Nodes::OuterJoin)
            .on(SchoolMove.arel_table[:patient_id].eq(patient_subquery[:id]))
            .join_sources
        )
        .where(patient_subquery[:id].not_eq(nil))
        .or(scope.where(school: team.schools))
        .or(scope.where(team:))
    end
  end
end
