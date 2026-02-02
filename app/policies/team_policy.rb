# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  def index? = false
  def create? = false
  def update? = false
  def destroy? = false

  def show? = team.has_point_of_care_access? && record == team

  alias_method :contact_details?, :show?
  alias_method :schools?, :show?
  alias_method :clinics?, :show?
  alias_method :sessions?, :show?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(id: team.id)
  end
end
