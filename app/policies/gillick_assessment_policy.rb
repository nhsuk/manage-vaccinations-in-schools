# frozen_string_literal: true

class GillickAssessmentPolicy < ApplicationPolicy
  def create?
    user.is_nurse?
  end

  def new?
    create?
  end

  def edit?
    user.is_nurse?
  end

  def update?
    edit?
  end
end
