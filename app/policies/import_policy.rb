# frozen_string_literal: true

class ImportPolicy < ApplicationPolicy
  def index? = true

  def create? = true

  def show? = true

  def update? = true

  def records? = true
end
