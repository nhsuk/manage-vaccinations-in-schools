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

      vaccination_records =
        VaccinationRecord
          .left_outer_joins(:session)
          .where(session: { organisation: })
          .or(
            VaccinationRecord.where(performed_ods_code: organisation.ods_code)
          )

      scope
        .where(organisation:)
        .or(
          scope.where(
            school_moves.where("patient_id = patients.id").arel.exists
          )
        )
        .or(
          scope.where(
            vaccination_records.where("patient_id = patients.id").arel.exists
          )
        )
    end
  end
end
