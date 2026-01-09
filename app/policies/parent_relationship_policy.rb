# frozen_string_literal: true

class ParentRelationshipPolicy < ApplicationPolicy
  def confirm_destroy? = destroy?
end
