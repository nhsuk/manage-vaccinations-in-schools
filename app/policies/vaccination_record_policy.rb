# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def new?
    create?
  end

  def edit?
    user.is_nurse? && record.session_id.present? &&
      record.performed_ods_code == user.selected_team.ods_code
  end

  def update?
    edit?
  end

  def destroy?
    user.is_superuser?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      scope
        .kept
        .where(patient: team.patients)
        .or(scope.kept.where(session: team.sessions))
        .or(scope.kept.where(performed_ods_code: team.ods_code))
    end
  end
end
