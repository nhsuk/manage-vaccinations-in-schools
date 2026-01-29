# frozen_string_literal: true

class Import::IssuePolicy < ApplicationPolicy
  def index? = !team.has_national_reporting_access?

  def create? = !team.has_national_reporting_access?

  def show? = !team.has_national_reporting_access?

  def update? = !team.has_national_reporting_access?
end
