# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def update?
    super && record.open?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
