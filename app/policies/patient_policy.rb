# frozen_string_literal: true

class PatientPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:location)
    end
  end
end
