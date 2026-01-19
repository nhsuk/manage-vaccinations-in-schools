# frozen_string_literal: true

class Import::IssuePolicy < ApplicationPolicy
  def index? = !team.has_upload_only_access?

  def create? = !team.has_upload_only_access?

  def show? = !team.has_upload_only_access?

  def update? = !team.has_upload_only_access?
end
