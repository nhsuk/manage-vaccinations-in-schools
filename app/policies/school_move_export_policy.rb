# frozen_string_literal: true

class SchoolMoveExportPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?

  def show? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?

  def download? = create?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
