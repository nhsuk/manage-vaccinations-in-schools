# frozen_string_literal: true

class GillickAssessmentPolicy < ApplicationPolicy
  def create?
    user.is_nurse? || user.is_prescriber?
  end

  def update?
    user.is_nurse? || user.is_prescriber?
  end
end
