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
    user.is_nurse? && record.session.open?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .kept
        .joins(:session)
        .where(session: { organisation: user.selected_organisation })
    end
  end
end
