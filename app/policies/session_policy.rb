# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?

  def show? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?

  def import? = show?

  def make_in_progress? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.for_team(team)
  end
end
