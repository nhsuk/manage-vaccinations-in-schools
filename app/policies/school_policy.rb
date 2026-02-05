# frozen_string_literal: true

class SchoolPolicy < LocationPolicy
  def import? = team.has_point_of_care_access?

  def patients? = team.has_point_of_care_access?

  def sessions? = team.has_point_of_care_access?

  def new? = team.has_point_of_care_access?

  def create? = team.has_point_of_care_access?
end
