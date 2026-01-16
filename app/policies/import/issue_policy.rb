# frozen_string_literal: true

class Import::IssuePolicy < ApplicationPolicy
  def index? = true

  def create? = true

  def show? = true

  def update? = true
end
