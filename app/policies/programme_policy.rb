# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  def sessions? = index?

  def patients = index?
end
