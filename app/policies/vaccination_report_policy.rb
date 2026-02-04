# frozen_string_literal: true

class VaccinationReportPolicy < ApplicationPolicy
  def create? = team.has_point_of_care_access?

  def update? = team.has_point_of_care_access?

  def download? = create?
end
