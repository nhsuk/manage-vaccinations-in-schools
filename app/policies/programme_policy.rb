# frozen_string_literal: true

class ProgrammePolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(id: @user.programmes.ids)
    end
  end
end
