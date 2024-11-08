# frozen_string_literal: true

class GillickAssessmentPolicy < ApplicationPolicy
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
      scope.joins(:session).where(
        session: {
          organisation: user.selected_organisation
        }
      )
    end
  end
end
