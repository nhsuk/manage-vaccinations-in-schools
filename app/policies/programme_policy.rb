# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  def index? = true

  def show? = true

  def sessions? = index?

  def patients = index?
end
