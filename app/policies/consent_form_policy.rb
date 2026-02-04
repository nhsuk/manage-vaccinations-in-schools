# frozen_string_literal: true

class ConsentFormPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?

  def show? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?

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
      team ? scope.for_team(team) : scope.none
    end
  end
end
