# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def make_in_progress?
    user.is_nurse? || user.is_admin?
  end

  def send_extra_consent_reminders?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(organisation: user.selected_organisation)
    end
  end
end
