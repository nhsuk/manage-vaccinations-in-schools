# frozen_string_literal: true

class VaccinePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:programme).where(
        programme: user.selected_organisation.programmes
      )
    end
  end
end
