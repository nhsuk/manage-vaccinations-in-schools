# frozen_string_literal: true

class ImportPolicy < ApplicationPolicy
  def index? = team.is_sais_team?

  def create? = team.is_sais_team?

  def show? = team.is_sais_team?

  def update? = team.is_sais_team?

  def records? = team.is_sais_team?
end
