# frozen_string_literal: true

class Import::BulkRemoveParentPolicy < ApplicationPolicy
  def create?
    team.has_poc_only_access? && Flipper.enabled?(:import_bulk_remove_parents)
  end
end
