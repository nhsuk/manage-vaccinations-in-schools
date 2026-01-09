# frozen_string_literal: true

class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @team = user.selected_team
    @record = record
  end

  attr_reader :user, :team, :record

  def index? = false

  def new? = create?

  def create? = false

  def show? = false

  def edit? = update?

  def update? = false

  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @team = user.selected_team
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    attr_reader :user, :team, :scope
  end
end
