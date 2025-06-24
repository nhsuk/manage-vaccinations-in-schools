# frozen_string_literal: true

class ConsentReminderPolicy < ApplicationPolicy
  def show?
    user.is_nurse? || user.is_admin?
  end

  def create?
    user.is_nurse? || user.is_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
