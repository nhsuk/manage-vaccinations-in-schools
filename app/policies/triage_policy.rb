# frozen_string_literal: true

class TriagePolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create?
    team.has_poc_only_access? && (user.is_nurse? || user.is_prescriber?)
  end

  def show? = team.has_poc_only_access?

  def update?
    team.has_poc_only_access? && (user.is_nurse? || user.is_prescriber?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team: [nil, team])
  end
end
