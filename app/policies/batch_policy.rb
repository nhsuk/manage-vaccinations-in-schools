# frozen_string_literal: true

class BatchPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.joins(:programmes).where(programmes: @user.programmes)
    end
  end
end
