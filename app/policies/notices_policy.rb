# frozen_string_literal: true

class NoticesPolicy < ApplicationPolicy
  def index?
    user.is_superuser?
  end
end
