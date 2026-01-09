# frozen_string_literal: true

class VaccinePolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def show? = team.has_poc_only_access?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(programme_type: team.programme_types)
    end
  end
end
