# frozen_string_literal: true

class GillickAssessmentPolicy < ApplicationPolicy
  def create?
    user.can_prescribe_pgd?
  end

  def new?
    create?
  end

  def edit?
    user.can_prescribe_pgd?
  end

  def update?
    edit?
  end
end
