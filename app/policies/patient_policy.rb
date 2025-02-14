# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation

      return scope.none if organisation.nil?

      school_moves =
        SchoolMove.where(organisation:).or(
          SchoolMove.where(school: organisation.schools)
        )

      scope.where(organisation:).or(
        scope.where(school_moves.where("patient_id = patients.id").arel.exists)
      )
    end
  end
end
