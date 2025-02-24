# frozen_string_literal: true

class ProgrammePolicy < ApplicationPolicy
  alias_method :sessions?, :index?
  alias_method :patients?, :index?

  def consent_form?
    user.is_nurse? || user.is_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.selected_organisation.programmes.ids)
    end
  end
end
