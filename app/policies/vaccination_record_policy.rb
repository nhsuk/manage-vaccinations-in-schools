# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def new?
    create?
  end

  def edit?
    user.is_nurse? &&
      record.performed_ods_code == user.selected_organisation.ods_code &&
      (record.session_id.present? || record.already_had?)
  end

  def update?
    edit?
  end

  def destroy?
    user.is_superuser?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation

      scope
        .kept
        .where(patient: organisation.patients)
        .or(scope.kept.where(session: organisation.sessions))
        .or(scope.kept.where(performed_ods_code: organisation.ods_code))
    end
  end
end
