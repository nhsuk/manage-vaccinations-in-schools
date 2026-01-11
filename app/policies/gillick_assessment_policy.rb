# frozen_string_literal: true

class GillickAssessmentPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create?
    team.has_poc_only_access? && (user.is_nurse? || user.is_prescriber?)
  end

  def show? = team.has_poc_only_access?

  def update?
    team.has_poc_only_access? && (user.is_nurse? || user.is_prescriber?)
  end
end
