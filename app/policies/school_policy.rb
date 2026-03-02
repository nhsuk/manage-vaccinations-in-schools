# frozen_string_literal: true

class SchoolPolicy < LocationPolicy
  def new? = team.has_point_of_care_access?

  def edit? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?
end
