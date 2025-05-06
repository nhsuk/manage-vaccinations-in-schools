# frozen_string_literal: true

class ConsentNotificationPolicy < ApplicationPolicy
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
