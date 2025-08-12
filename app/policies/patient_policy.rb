# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      team = user.selected_team

      return scope.none if team.nil?

      patient_session_exists =
        PatientSession
          .where("patient_sessions.patient_id = patients.id")
          .where(session: team.sessions)
          .arel
          .exists

      school_move_exists =
        SchoolMove
          .where("school_moves.patient_id = patients.id")
          .where(team:)
          .or(
            SchoolMove.where("school_moves.patient_id = patients.id").where(
              school: team.schools
            )
          )
          .arel
          .exists

      vaccination_records_for_patients =
        VaccinationRecord.where("vaccination_records.patient_id = patients.id")

      vaccination_record_exists =
        vaccination_records_for_patients
          .where(session: team.sessions)
          .or(
            vaccination_records_for_patients.where(
              performed_ods_code: organisation.ods_code,
              session_id: nil
            )
          )
          .arel
          .exists

      scope
        .archived(team:)
        .or(scope.where(patient_session_exists))
        .or(scope.where(school_move_exists))
        .or(scope.where(vaccination_record_exists))
    end
  end
end
