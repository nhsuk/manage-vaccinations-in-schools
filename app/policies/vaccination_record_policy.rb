# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def new?
    create?
  end

  def edit?
    user.is_nurse?
  end

  def update?
    edit?
  end

  def destroy?
    user.is_superuser?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .kept
        .where(patient: PatientPolicy::Scope.new(user, Patient).resolve)
        .or(
          scope.kept.where(
            session: SessionPolicy::Scope.new(user, Session).resolve
          )
        )
        .or(
          scope.kept.where(
            performed_ods_code: user.selected_organisation.ods_code
          )
        )
    end
  end
end
