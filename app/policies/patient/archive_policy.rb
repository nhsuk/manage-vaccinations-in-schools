# frozen_string_literal: true

class Patient::ArchivePolicy < ApplicationPolicy
  def create? = team.has_point_of_care_access?
end
