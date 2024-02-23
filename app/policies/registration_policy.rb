class RegistrationPolicy
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.includes(:location).where(location: @user.team.locations)
    end
  end
end
