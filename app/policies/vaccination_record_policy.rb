# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def new?
    create?
  end

  def record_already_vaccinated?
    user.is_nurse? && !session.today? &&
      patient.vaccination_status(programme:, academic_year:).none_yet?
  end

  def edit?
    user.is_nurse? && record.session_id.present? &&
      record.performed_ods_code == user.selected_organisation.ods_code
  end

  def update?
    edit?
  end

  def destroy?
    user.is_superuser?
  end

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
