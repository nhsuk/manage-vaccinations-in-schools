# frozen_string_literal: true

class NoticesPolicy < ApplicationPolicy
  def index?
    user.can_access_sensitive_records?
  end
end
