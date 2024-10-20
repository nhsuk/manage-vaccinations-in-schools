# frozen_string_literal: true

class VaccinePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:programme).where(programme: user.programmes)
    end
  end
end
