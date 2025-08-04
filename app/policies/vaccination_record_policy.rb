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
      record.performed_ods_code == user.selected_organisation.ods_code
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
      return scope.none if organisation.nil?

      scope
        .kept
        .where(patient: organisation.patients)
        .or(scope.kept.where(session: organisation.sessions))
        .or(scope.kept.where(performed_ods_code: organisation.ods_code))
    end
  end
end
