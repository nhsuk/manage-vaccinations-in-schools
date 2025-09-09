# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      team = user.selected_team

      return scope.none if team.nil?

      patients_table = Patient.arel_table
      associated_patients_table = Arel::Table.new("associated_patients")

      associated_patients = [
        PatientSession
          .select(:patient_id)
          .joins(:session)
          .where(sessions: { team_id: team.id })
          .arel,
        ArchiveReason.select(:patient_id).where(team_id: team.id).arel,
        SchoolMove.select(:patient_id).where(team_id: team.id).arel,
        SchoolMove.select(:patient_id).where(school: team.schools).arel,
        VaccinationRecord
          .select(:patient_id)
          .joins(:session)
          .where(sessions: { team_id: team.id })
          .arel,
        VaccinationRecord
          .select(:patient_id)
          .where(performed_ods_code: organisation.ods_code, session_id: nil)
          .arel
      ]

      associated_patiens_union =
        Arel::Nodes::Union.new(associated_patients[0], associated_patients[1])
      associated_patients[2..].each do |select|
        associated_patiens_union =
          Arel::Nodes::Union.new(associated_patiens_union, select)
      end

      associated_patients_query =
        Arel::SelectManager
          .new
          .project(Arel.star)
          .from(associated_patiens_union.as("t"))
          .group("t.patient_id")

      join_associated_patients =
        patients_table
          .join(associated_patients_table)
          .on(associated_patients_table[:patient_id].eq(patients_table[:id]))
          .join_sources
          .first

      Patient.with(associated_patients: associated_patients_query).joins(
        join_associated_patients
      )
    end
  end
end
