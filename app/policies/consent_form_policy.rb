# frozen_string_literal: true

class ConsentFormPolicy < ApplicationPolicy
  def search? = show?

  def download? = show?

  def new_patient? = new?

  def create_patient? = create?

  def edit_match? = edit?

  def update_match? = update?

  def edit_archive? = edit?

  def update_archive? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      scope.for_team(team)
    end
  end
end
