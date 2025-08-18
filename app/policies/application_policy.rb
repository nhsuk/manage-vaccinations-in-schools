# frozen_string_literal: true

class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  attr_reader :user, :record

  def index?
    true
  end

  def new?
    create?
  end

  def create?
    true
  end

  def show?
    true
  end

  def edit?
    update?
  end

  def update?
    true
  end

  def destroy?
    true
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    attr_reader :user, :scope
  end
end
