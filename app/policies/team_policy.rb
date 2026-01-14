# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  def index? = false

  def create? = false

  def show? = team.has_poc_only_access? && record == team

  def update? = false

  def destroy? = false

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(id: team.id)
  end
end
