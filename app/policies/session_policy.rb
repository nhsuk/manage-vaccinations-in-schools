# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def make_in_progress?
    user.is_nurse? || user.is_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
