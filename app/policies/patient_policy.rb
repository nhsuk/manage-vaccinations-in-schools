# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation

      return scope.none if organisation.nil?

      scope_with_joins =
        scope.left_outer_joins(
          :patient_sessions,
          :school_moves,
          :vaccination_records
        )

      scope_with_joins
        .where(patient_sessions: { session: organisation.sessions })
        .or(scope_with_joins.where(school_moves: { organisation: }))
        .or(
          scope_with_joins.where(school_moves: { school: organisation.schools })
        )
        .or(
          scope_with_joins.where(
            vaccination_records: {
              session: organisation.sessions
            }
          )
        )
        .or(
          scope_with_joins.where(
            vaccination_records: {
              performed_ods_code: organisation.ods_code
            }
          )
        )
    end
  end
end
