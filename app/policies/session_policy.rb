# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def update?
    super && record.open?
  end

  def edit_close?
    update_close?
  end

  def update_close?
    (user.is_nurse? || user.is_admin?) && record.open? && record.completed?
  end

  def consent_form?
    user.is_nurse? || user.is_admin?
  end

  def make_in_progress?
    user.is_nurse? || user.is_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
