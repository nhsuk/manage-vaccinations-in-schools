# frozen_string_literal: true

class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  attr_reader :user, :record

  def index?
    user.is_nurse? || user.is_medical_secretary?
  end

  def show?
    user.is_nurse? || user.is_medical_secretary?
  end

  def create?
    user.is_nurse? || user.is_medical_secretary?
  end

  def new?
    create?
  end

  def update?
    user.is_nurse? || user.is_medical_secretary?
  end

  def edit?
    update?
  end

  def destroy?
    user.is_nurse? || user.is_medical_secretary?
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
