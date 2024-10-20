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

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:session).where(session: { team: user.teams })
    end
  end
end
