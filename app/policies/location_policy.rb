# frozen_string_literal: true

class LocationPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope
    end
  end
end
