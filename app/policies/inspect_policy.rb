# frozen_string_literal: true

class InspectPolicy < ApplicationPolicy
  def dashboard? = has_support_access?
  def graph? = has_support_access?
  def timeline? = has_support_access?

  def show_pii?
    team&.has_support_access? && user.is_support_with_pii_access?
  end

  private

  def has_support_access?
    team&.has_support_access? && user.is_support?
  end
end
