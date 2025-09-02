# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.is_nurse? || user.is_prescriber? ||
      (
        patient.approved_vaccine_methods(programme:, academic_year:) &
          session.vaccine_methods_for(user:)
      ).present?
  end

  def new? = create?

  def record_already_vaccinated?
    (user.is_nurse? || user.is_prescriber?) && !session.today? &&
      patient.vaccination_status(programme:, academic_year:).none_yet?
  end

  def edit?
    (
      record.performed_by_user_id == user.id || user.is_nurse? ||
        user.is_prescriber?
    ) && record.recorded_in_service? &&
      record.performed_ods_code == user.selected_organisation.ods_code
  end

  def update? = edit?

  def destroy? = user.is_superuser?

  delegate :patient, :session, :programme, to: :record
  delegate :academic_year, to: :session

  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      team = user.selected_team
      return scope.none if team.nil?

      scope
        .kept
        .where(patient: team.patients)
        .or(scope.kept.where(session: team.sessions))
        .or(
          scope.kept.where(
            performed_ods_code: organisation.ods_code,
            session_id: nil
          )
        )
    end
  end
end
