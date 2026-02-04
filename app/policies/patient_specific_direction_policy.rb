# frozen_string_literal: true

class PatientSpecificDirectionPolicy < ApplicationPolicy
  def index? = team.has_point_of_care_access?

  def create?
    team.has_point_of_care_access? && user.is_prescriber?
  end

  def show? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?
end
