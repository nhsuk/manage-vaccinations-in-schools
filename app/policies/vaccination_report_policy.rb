# frozen_string_literal: true

class VaccinationReportPolicy < ApplicationPolicy
  def create? = team.has_poc_only_access?

  def update? = team.has_poc_only_access?

  def download? = create?
end
