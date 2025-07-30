# frozen_string_literal: true

class LocationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:subteam).where(
        subteam: {
          organisation: user.selected_organisation
        }
      )
    end
  end
end
