# frozen_string_literal: true

class ImmunisationImportPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  def show? = true

  def update? = true

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team:)
  end
end
