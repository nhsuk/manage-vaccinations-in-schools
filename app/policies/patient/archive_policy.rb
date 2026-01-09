# frozen_string_literal: true

class Patient::ArchivePolicy < ApplicationPolicy
  def create? = team.has_poc_only_access?
end
