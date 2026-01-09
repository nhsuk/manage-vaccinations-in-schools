# frozen_string_literal: true

class VaccinationReportPolicy < ApplicationPolicy
  def download? = create?
end
