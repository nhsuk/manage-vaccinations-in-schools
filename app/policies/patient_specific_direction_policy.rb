# frozen_string_literal: true

class PatientSpecificDirectionPolicy < ApplicationPolicy
  def create?
    user.is_nurse? || user.is_prescriber?
  end
end
