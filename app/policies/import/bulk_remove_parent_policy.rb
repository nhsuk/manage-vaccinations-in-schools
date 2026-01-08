# frozen_string_literal: true

class Import::BulkRemoveParentPolicy < ApplicationPolicy
  def new? = Flipper.enabled?(:import_bulk_remove_parents)

  def create? = Flipper.enabled?(:import_bulk_remove_parents)
end
