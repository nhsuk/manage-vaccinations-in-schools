# frozen_string_literal: true

class BatchPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create? = team.has_poc_only_access?

  def show? = team.has_poc_only_access?

  def update? = team.has_poc_only_access?

  def edit_archive? = edit?

  def update_archive? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
