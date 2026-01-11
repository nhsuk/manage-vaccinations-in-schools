# frozen_string_literal: true

class ConsentPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create? = team.has_poc_only_access?

  def show? = team.has_poc_only_access?

  def update? = team.has_poc_only_access?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
