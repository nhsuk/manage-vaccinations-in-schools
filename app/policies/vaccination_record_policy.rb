# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    user.can_supply_using_pgd?
  end

  def new?
    create?
  end

  def edit?
    user.can_supply_using_pgd? && record.session_id.present? &&
      record.performed_ods_code == user.selected_organisation.ods_code
  end

  def update?
    edit?
  end

  def destroy?
    user.can_perform_local_admin_tasks?
  end

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
