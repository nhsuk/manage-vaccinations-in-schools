# frozen_string_literal: true

class ParentRelationshipPolicy < ApplicationPolicy
  def index? = team.has_poc_only_access?

  def create? = team.has_poc_only_access?

  def show? = team.has_poc_only_access?

  def update? = team.has_poc_only_access?

  def confirm_destroy? = destroy?

  def destroy? = team.has_poc_only_access?
end
