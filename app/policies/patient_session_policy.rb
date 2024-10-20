# frozen_string_literal: true

class PatientSessionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:session).where(session: { team: user.teams })
    end
  end
end
