# frozen_string_literal: true

class TriagePolicy < ApplicationPolicy
  def create?
    @user.is_nurse?
  end
end
