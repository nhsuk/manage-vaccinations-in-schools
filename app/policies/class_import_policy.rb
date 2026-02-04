# frozen_string_literal: true

class ClassImportPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?

  def show? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?

  def approve? = update?

  def re_review? = update?

  def cancel? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
