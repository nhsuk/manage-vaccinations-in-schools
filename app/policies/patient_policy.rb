# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      team = user.selected_team

      return scope.none if team.nil?

      existence_criteria = [
        PatientLocation
          .select("1")
          .joins_sessions
          .where("patient_locations.patient_id = patients.id")
          .where("sessions.team_id = ?", team.id)
          .arel,
        ArchiveReason
          .select("1")
          .where("archive_reasons.patient_id = patients.id")
          .where(team_id: team.id)
          .arel,
        SchoolMove
          .select("1")
          .where("school_moves.patient_id = patients.id")
          .where(team_id: team.id)
          .arel,
        SchoolMove
          .select("1")
          .where("school_moves.patient_id = patients.id")
          .where(school: team.schools)
          .arel,
        VaccinationRecord
          .select("1")
          .joins(:session)
          .where("vaccination_records.patient_id = patients.id")
          .where(sessions: { team_id: team.id })
          .arel,
        VaccinationRecord
          .select("1")
          .where("vaccination_records.patient_id = patients.id")
          .where(performed_ods_code: organisation.ods_code, session_id: nil)
          .arel
      ]

      condition = existence_criteria[0].exists
      existence_criteria[1..].each do |filter|
        condition = condition.or(filter.exists)
      end
      scope.where(condition)
    end
  end
end
