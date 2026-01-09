# frozen_string_literal: true

class ClassImportPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create? = team.has_poc_only_access?

  def show? = team.has_poc_only_access?

  def update? = team.has_poc_only_access?

  def approve? = update?

  def re_review? = update?

  def cancel? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
